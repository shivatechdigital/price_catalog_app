import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/submit_multi_requirement_screen.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class SelectProductsScreen extends ConsumerStatefulWidget {
  const SelectProductsScreen({super.key});

  @override
  ConsumerState<SelectProductsScreen> createState() =>
      _SelectProductsScreenState();
}

class _SelectProductsScreenState extends ConsumerState<SelectProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear previous selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedRequirementItemsProvider.notifier).state = [];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // TOGGLE PRODUCT SELECTION
  // ═══════════════════════════════════════
  void _toggleProduct(ProductModel product) {
    final currentItems = ref.read(selectedRequirementItemsProvider);
    final exists = currentItems.any((i) => i.productId == product.id);

    if (exists) {
      // Remove
      ref.read(selectedRequirementItemsProvider.notifier).state =
          currentItems.where((i) => i.productId != product.id).toList();
    } else {
      // Add with default values
      final newItem = RequirementItemModel(
        productId: product.id,
        productName: product.name,
        productCode: product.productCode,
        productImage: product.primaryImage.isNotEmpty
            ? product.primaryImage
            : null,
        categoryName: product.categoryName,
        quantity: 1,
        unit: product.unit,
        productCurrentPrice: product.currentPrice.sellingPrice,
        customerDemandedPrice: product.currentPrice.sellingPrice,
        traderOfferedPrice: product.currentPrice.sellingPrice,
      );

      ref.read(selectedRequirementItemsProvider.notifier).state = [
        ...currentItems,
        newItem
      ];
    }
  }

  // ═══════════════════════════════════════
  // PROCEED TO NEXT STEP
  // ═══════════════════════════════════════
  void _proceed() {
    final selectedItems = ref.read(selectedRequirementItemsProvider);
    if (selectedItems.isEmpty) {
      CustomSnackbar.showWarning(
        context,
        'Please select at least one product',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubmitMultiRequirementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = ref.watch(selectedRequirementItemsProvider);
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

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
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            title: Column(
              children: [
                Text(
                  'Select Products',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${selectedItems.length} selected',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: selectedItems.isEmpty
                        ? AppColors.textHint
                        : AppColors.traderPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(110.h),
              child: Column(
                children: [
                  // Search
                  Container(
                    color: AppColors.white,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(
                          Iconsax.search_normal,
                          size: 20.sp,
                          color: AppColors.textHint,
                        ),
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
                  ),
                  // Category chips
                  Container(
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
                            return _buildChip(
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
                          return _buildChip(
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
                  ),
                ],
              ),
            ),
          ),
        ],
        body: filteredProductsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const Center(
            child: Text('Failed to load products'),
          ),
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
              itemCount: products.length,
              separatorBuilder: (_, __) => Gap(10.h),
              itemBuilder: (context, index) {
                final product = products[index];
                final isSelected =
                    selectedItems.any((i) => i.productId == product.id);
                final isOutOfStock =
                    product.availability == ProductAvailability.outOfStock;

                return _ProductSelectTile(
                  product: product,
                  isSelected: isSelected,
                  isOutOfStock: isOutOfStock,
                  onTap: isOutOfStock
                      ? null
                      : () => _toggleProduct(product),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: index * 40),
                      duration: 250.ms,
                    );
              },
            );
          },
        ),
      ),

      // ─── BOTTOM BAR ─────────────────────────────────────
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: selectedItems.isEmpty ? 0 : null,
        child: _buildBottomBar(selectedItems),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SELECTED ITEMS BOTTOM BAR
  // ═══════════════════════════════════════
  Widget _buildBottomBar(List<RequirementItemModel> selectedItems) {
    if (selectedItems.isEmpty) return const SizedBox();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected Products Preview
          SizedBox(
            height: 52.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedItems.length,
              separatorBuilder: (_, __) => Gap(8.w),
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                return GestureDetector(
                  onTap: () {
                    // Remove on tap
                    ref
                        .read(selectedRequirementItemsProvider.notifier)
                        .state = selectedItems
                        .where((i) => i.productId != item.productId)
                        .toList();
                  },
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.traderPrimary,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: item.productImage != null
                              ? CachedNetworkImage(
                                  imageUrl: item.productImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: AppColors.traderPrimary.withOpacity(0.1),
                                  child: Icon(
                                    Iconsax.box,
                                    size: 20.sp,
                                    color: AppColors.traderPrimary,
                                  ),
                                ),
                        ),
                        // Remove badge
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16.w,
                            height: 16.w,
                            decoration: const BoxDecoration(
                              color: AppColors.rejected,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 10.sp,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Gap(12.h),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.traderPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
                size: 20.sp,
              ),
              label: Text(
                'Continue with ${selectedItems.length} ${selectedItems.length == 1 ? 'Product' : 'Products'}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// PRODUCT SELECT TILE
// ═══════════════════════════════════════
class _ProductSelectTile extends StatelessWidget {
  final ProductModel product;
  final bool isSelected;
  final bool isOutOfStock;
  final VoidCallback? onTap;

  const _ProductSelectTile({
    required this.product,
    required this.isSelected,
    required this.isOutOfStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isOutOfStock
              ? AppColors.background
              : isSelected
                  ? AppColors.traderPrimary.withOpacity(0.06)
                  : AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isOutOfStock
                ? AppColors.border
                : isSelected
                    ? AppColors.traderPrimary
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isOutOfStock
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ─── Checkbox ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? AppColors.border
                    : isSelected
                        ? AppColors.traderPrimary
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isOutOfStock
                      ? AppColors.border
                      : isSelected
                          ? AppColors.traderPrimary
                          : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14.sp,
                      color: AppColors.white,
                    )
                  : null,
            ),

            Gap(12.w),

            // ─── Product Image ──────────────────────────
            Opacity(
              opacity: isOutOfStock ? 0.5 : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 58.w,
                  height: 58.w,
                  child: product.primaryImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.traderPrimary.withOpacity(0.08),
                          child: Icon(
                            Iconsax.box,
                            size: 26.sp,
                            color: AppColors.traderPrimary.withOpacity(0.4),
                          ),
                        ),
                ),
              ),
            ),

            Gap(12.w),

            // ─── Product Info ───────────────────────────
            Expanded(
              child: Opacity(
                opacity: isOutOfStock ? 0.5 : 1,
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
                    Gap(5.h),
                    Row(
                      children: [
                        Text(
                          '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.traderPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '/${product.unit}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Availability Badge ─────────────────────
            _AvailabilityBadge(availability: product.availability),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final ProductAvailability availability;

  const _AvailabilityBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, text) = switch (availability) {
      ProductAvailability.inStock => (
          AppColors.approved,
          AppColors.approvedLight,
          'In Stock'
        ),
      ProductAvailability.outOfStock => (
          AppColors.rejected,
          AppColors.rejectedLight,
          'Out of Stock'
        ),
      ProductAvailability.limitedStock => (
          AppColors.counter,
          AppColors.counterLight,
          'Limited'
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

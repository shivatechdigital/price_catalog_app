import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/features/admin/products/screens/add_product_screen.dart';
import 'package:price_catalog_app/features/admin/products/screens/admin_product_detail_screen.dart';
import 'package:price_catalog_app/features/admin/products/widgets/admin_product_grid_card.dart';
import 'package:price_catalog_app/features/admin/products/widgets/admin_product_list_tile.dart';
import 'package:price_catalog_app/features/admin/products/widgets/product_filter_sheet.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';

// ═══════════════════════════════════════
// VIEW MODE PROVIDER
// ═══════════════════════════════════════
enum ViewMode { grid, list }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState
    extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final viewMode = ref.watch(viewModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ═══════════════════════════════════════
          // APP BAR
          // ═══════════════════════════════════════
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: innerBoxIsScrolled ? 2 : 0,
            title: Text(
              'Products',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              // View Toggle
              Container(
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggleBtn(
                      icon: Icons.grid_view_rounded,
                      isActive: viewMode == ViewMode.grid,
                      onTap: () => ref
                          .read(viewModeProvider.notifier)
                          .state = ViewMode.grid,
                    ),
                    _ViewToggleBtn(
                      icon: Icons.view_list_rounded,
                      isActive: viewMode == ViewMode.list,
                      onTap: () => ref
                          .read(viewModeProvider.notifier)
                          .state = ViewMode.list,
                    ),
                  ],
                ),
              ),
              // Add Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductScreen(),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(right: 16.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.adminPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18.sp,
                        color: AppColors.white,
                      ),
                      Gap(4.w),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(116.h),
              child: Column(
                children: [
                  // Search Bar
                  _buildSearchBar(),
                  // Category Filter Chips
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
        ],
        body: filteredProductsAsync.when(
          loading: () => viewMode == ViewMode.grid
              ? _buildGridShimmer()
              : _buildListShimmer(),
          error: (e, _) => _buildErrorState(),
          data: (products) {
            if (products.isEmpty) {
              return searchQuery.isNotEmpty || selectedCategory != null
                  ? _buildNoResults()
                  : _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productsStreamProvider);
              },
              color: AppColors.adminPrimary,
              child: viewMode == ViewMode.grid
                  ? _buildGridView(products)
                  : _buildListView(products),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
                suffixIcon:
                    ref.watch(searchQueryProvider).isNotEmpty
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
          ),
          Gap(10.w),
          // Filter Button
          GestureDetector(
            onTap: () => _showFilterSheet(),
            child: Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: ref.watch(selectedCategoryFilterProvider) != null
                    ? AppColors.adminPrimary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Iconsax.filter,
                size: 20.sp,
                color: ref.watch(selectedCategoryFilterProvider) != null
                    ? AppColors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // CATEGORY CHIPS
  // ═══════════════════════════════════════
  Widget _buildCategoryChips() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

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
              // "All" chip
              return _CategoryChip(
                label: 'All',
                icon: '📦',
                isSelected: selectedCategory == null,
                onTap: () => ref
                    .read(selectedCategoryFilterProvider.notifier)
                    .state = null,
              );
            }
            final category = categories[index - 1];
            return _CategoryChip(
              label: category.name,
              icon: category.icon,
              isSelected: selectedCategory == category.id,
              onTap: () => ref
                  .read(selectedCategoryFilterProvider.notifier)
                  .state = category.id,
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // FILTER SHEET
  // ═══════════════════════════════════════
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProductFilterSheet(),
    );
  }

  // ═══════════════════════════════════════
  // GRID VIEW
  // ═══════════════════════════════════════
  Widget _buildGridView(List<ProductModel> products) {
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
        return AdminProductGridCard(
          product: products[index],
          onTap: () => _navigateToDetail(products[index]),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 60),
              duration: 300.ms,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
              delay: Duration(milliseconds: index * 60),
            );
      },
    );
  }

  // ═══════════════════════════════════════
  // LIST VIEW
  // ═══════════════════════════════════════
  Widget _buildListView(List<ProductModel> products) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      itemCount: products.length,
      separatorBuilder: (_, __) => Gap(10.h),
      itemBuilder: (context, index) {
        return AdminProductListTile(
          product: products[index],
          onTap: () => _navigateToDetail(products[index]),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 60),
              duration: 300.ms,
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  void _navigateToDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductDetailScreen(product: product),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHIMMER
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

  // ═══════════════════════════════════════
  // EMPTY + ERROR STATES
  // ═══════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.box,
              size: 48.sp,
              color: AppColors.adminPrimary,
            ),
          ),
          Gap(20.h),
          Text(
            'No Products Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Add your first product to get started',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Gap(28.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddProductScreen(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.white),
            label: Text(
              'Add Product',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_normal,
            size: 52.sp,
            color: AppColors.textHint,
          ),
          Gap(16.h),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Try different search or filters',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Gap(16.h),
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
              ref
                  .read(selectedCategoryFilterProvider.notifier)
                  .state = null;
            },
            child: Text(
              'Clear Filters',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 52.sp,
            color: AppColors.rejected,
          ),
          Gap(16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(12.h),
          ElevatedButton(
            onPressed: () => ref.invalidate(productsStreamProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// VIEW TOGGLE BUTTON
// ═══════════════════════════════════════
class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: isActive ? AppColors.adminPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color:
              isActive ? AppColors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// CATEGORY CHIP
// ═══════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              ? AppColors.adminPrimary
              : AppColors.background,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.adminPrimary
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
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/category_model.dart';
import 'package:price_catalog_app/features/admin/categories/widgets/add_edit_category_sheet.dart';
import 'package:price_catalog_app/features/admin/categories/widgets/category_list_tile.dart';
import 'package:price_catalog_app/features/admin/categories/widgets/delete_category_dialog.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState
    extends ConsumerState<AdminCategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // SHOW ADD CATEGORY SHEET
  // ═══════════════════════════════════════
  void _showAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditCategorySheet(),
    );
  }

  // ═══════════════════════════════════════
  // SHOW EDIT CATEGORY SHEET
  // ═══════════════════════════════════════
  void _showEditCategorySheet(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditCategorySheet(category: category),
    );
  }

  // ═══════════════════════════════════════
  // SHOW DELETE DIALOG
  // ═══════════════════════════════════════
  void _showDeleteDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (_) => DeleteCategoryDialog(
        category: category,
        onConfirm: () => _deleteCategory(category),
      ),
    );
  }

  // ═══════════════════════════════════════
  // DELETE CATEGORY
  // ═══════════════════════════════════════
  Future<void> _deleteCategory(CategoryModel category) async {
    if (category.productCount > 0) {
      CustomSnackbar.showWarning(
        context,
        'Cannot delete. Category has ${category.productCount} products.',
      );
      return;
    }

    final success = await ref
        .read(categoryNotifierProvider.notifier)
        .deleteCategory(category.id);

    if (!mounted) return;

    if (success) {
      CustomSnackbar.showSuccess(
        context,
        '${category.name} deleted successfully',
      );
    } else {
      CustomSnackbar.showError(context, 'Failed to delete category');
    }
  }

  // ═══════════════════════════════════════
  // TOGGLE ACTIVE STATUS
  // ═══════════════════════════════════════
  Future<void> _toggleActive(CategoryModel category) async {
    await ref.read(categoryNotifierProvider.notifier).updateCategory(
          categoryId: category.id,
          isActive: !category.isActive,
        );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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
              'Categories',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              // Add Button
              GestureDetector(
                onTap: _showAddCategorySheet,
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
              preferredSize: Size.fromHeight(64.h),
              child: _buildSearchBar(),
            ),
          ),
        ],
        body: categoriesAsync.when(
          loading: () => _buildShimmerList(),
          error: (error, _) => _buildErrorState(),
          data: (categories) {
            // Filter by search
            final filtered = _searchQuery.isEmpty
                ? categories
                : categories
                    .where((c) => c.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

            if (filtered.isEmpty) {
              return _searchQuery.isNotEmpty
                  ? _buildNoSearchResults()
                  : _buildEmptyState();
            }

            return _buildCategoryList(filtered);
          },
        ),
      ),
      // ═══════════════════════════════════════
      // FAB
      // ═══════════════════════════════════════
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategorySheet,
        backgroundColor: AppColors.adminPrimary,
        elevation: 4,
        icon: Icon(
          Icons.add_rounded,
          color: AppColors.white,
          size: 22.sp,
        ),
        label: Text(
          'New Category',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
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
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 20.sp,
            color: AppColors.textHint,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
  // CATEGORY LIST
  // ═══════════════════════════════════════
  Widget _buildCategoryList(List<CategoryModel> categories) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(categoriesStreamProvider),
      color: AppColors.adminPrimary,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Gap(10.h),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryListTile(
            category: category,
            onEdit: () => _showEditCategorySheet(category),
            onDelete: () => _showDeleteDialog(category),
            onToggleActive: () => _toggleActive(category),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 80),
                duration: 300.ms,
              )
              .slideX(
                begin: 0.05,
                end: 0,
                delay: Duration(milliseconds: index * 80),
              );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHIMMER LIST
  // ═══════════════════════════════════════
  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 6,
      separatorBuilder: (_, __) => Gap(10.h),
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: 90.h,
        borderRadius: 16.r,
      ),
    );
  }

  // ═══════════════════════════════════════
  // EMPTY STATES
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
              Iconsax.category,
              size: 48.sp,
              color: AppColors.adminPrimary,
            ),
          ),
          Gap(20.h),
          Text(
            'No Categories Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Add your first product category\nto get started',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(28.h),
          ElevatedButton.icon(
            onPressed: _showAddCategorySheet,
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
            icon: Icon(
              Icons.add_rounded,
              color: AppColors.white,
              size: 20.sp,
            ),
            label: Text(
              'Add Category',
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

  Widget _buildNoSearchResults() {
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
            'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
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
            onPressed: () => ref.invalidate(categoriesStreamProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
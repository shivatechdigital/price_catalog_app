import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';

class ProductFilterSheet extends ConsumerWidget {
  const ProductFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final selectedSort = ref.watch(sortOptionProvider);
    final selectedAvailability = ref.watch(availabilityFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),

          Gap(16.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(selectedCategoryFilterProvider.notifier)
                      .state = null;
                  ref.read(sortOptionProvider.notifier).state =
                      SortOption.recent;
                  ref
                      .read(availabilityFilterProvider.notifier)
                      .state = null;
                },
                child: Text(
                  'Reset All',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.rejected,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          Gap(16.h),

          // SORT OPTIONS
          _buildSectionTitle('Sort By'),
          Gap(10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _SortChip(
                label: 'Recent',
                isSelected: selectedSort == SortOption.recent,
                onTap: () => ref
                    .read(sortOptionProvider.notifier)
                    .state = SortOption.recent,
              ),
              _SortChip(
                label: 'Name A-Z',
                isSelected: selectedSort == SortOption.nameAsc,
                onTap: () => ref
                    .read(sortOptionProvider.notifier)
                    .state = SortOption.nameAsc,
              ),
              _SortChip(
                label: 'Name Z-A',
                isSelected: selectedSort == SortOption.nameDesc,
                onTap: () => ref
                    .read(sortOptionProvider.notifier)
                    .state = SortOption.nameDesc,
              ),
              _SortChip(
                label: 'Price ↑',
                isSelected: selectedSort == SortOption.priceAsc,
                onTap: () => ref
                    .read(sortOptionProvider.notifier)
                    .state = SortOption.priceAsc,
              ),
              _SortChip(
                label: 'Price ↓',
                isSelected: selectedSort == SortOption.priceDesc,
                onTap: () => ref
                    .read(sortOptionProvider.notifier)
                    .state = SortOption.priceDesc,
              ),
            ],
          ),

          Gap(20.h),

          // AVAILABILITY
          _buildSectionTitle('Availability'),
          Gap(10.h),
          Wrap(
            spacing: 8.w,
            children: [
              _SortChip(
                label: '✅ In Stock',
                isSelected: selectedAvailability ==
                    ProductAvailability.inStock,
                onTap: () => ref
                    .read(availabilityFilterProvider.notifier)
                    .state = ProductAvailability.inStock,
              ),
              _SortChip(
                label: '⚠️ Limited',
                isSelected: selectedAvailability ==
                    ProductAvailability.limitedStock,
                onTap: () => ref
                    .read(availabilityFilterProvider.notifier)
                    .state = ProductAvailability.limitedStock,
              ),
              _SortChip(
                label: '❌ Out of Stock',
                isSelected: selectedAvailability ==
                    ProductAvailability.outOfStock,
                onTap: () => ref
                    .read(availabilityFilterProvider.notifier)
                    .state = ProductAvailability.outOfStock,
              ),
            ],
          ),

          Gap(24.h),

          // APPLY BUTTON
          CustomButton(
            label: 'Apply Filters',
            gradient: AppColors.adminGradient,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
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
          horizontal: 14.w,
          vertical: 8.h,
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
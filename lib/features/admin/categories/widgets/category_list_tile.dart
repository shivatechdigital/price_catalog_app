import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/category_model.dart';

class CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const CategoryListTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: category.isActive
              ? AppColors.border
              : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══════════════════════════════════════
          // MAIN ROW
          // ═══════════════════════════════════════
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    gradient: category.isActive
                        ? AppColors.adminGradient
                        : const LinearGradient(
                            colors: [
                              AppColors.border,
                              AppColors.border,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ),
                ),

                Gap(14.w),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: category.isActive
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                          if (!category.isActive)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Inactive',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      Gap(4.h),

                      // Description
                      if (category.description.isNotEmpty)
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      Gap(6.h),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Iconsax.box,
                            label:
                                '${category.productCount} products',
                            color: AppColors.adminPrimary,
                          ),
                          Gap(8.w),
                          _buildStatChip(
                            icon: Iconsax.category,
                            label:
                                '${category.subCategories.length} sub',
                            color: AppColors.traderPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleActive();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: _buildMenuItem(
                        icon: Iconsax.edit,
                        label: 'Edit',
                        color: AppColors.adminPrimary,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: _buildMenuItem(
                        icon: category.isActive
                            ? Iconsax.eye_slash
                            : Iconsax.eye,
                        label: category.isActive
                            ? 'Deactivate'
                            : 'Activate',
                        color: category.isActive
                            ? AppColors.counter
                            : AppColors.approved,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: _buildMenuItem(
                        icon: Iconsax.trash,
                        label: 'Delete',
                        color: AppColors.rejected,
                      ),
                    ),
                  ],
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════
          // SUBCATEGORIES CHIPS
          // ═══════════════════════════════════════
          if (category.subCategories.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: category.subCategories.map((sub) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.adminPrimary.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sub.icon,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        Gap(4.w),
                        Text(
                          sub.name,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          Gap(4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
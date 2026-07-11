import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/category_model.dart';

class DeleteCategoryDialog extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onConfirm;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════
            // ICON
            // ═══════════════════════════════════
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: AppColors.rejectedLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.trash,
                size: 32.sp,
                color: AppColors.rejected,
              ),
            ),

            Gap(20.h),

            // ═══════════════════════════════════
            // TITLE
            // ═══════════════════════════════════
            Text(
              'Delete Category?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            Gap(8.h),

            // ═══════════════════════════════════
            // MESSAGE
            // ═══════════════════════════════════
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"${category.name}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text: '? This action cannot be undone.',
                  ),
                ],
              ),
            ),

            Gap(8.h),

            // Warning if has products
            if (category.productCount > 0)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.counterLight,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.counter.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 16.sp,
                      color: AppColors.counter,
                    ),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        'This category has ${category.productCount} products. '
                        'Please reassign or delete them first.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.counter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Gap(24.h),

            // ═══════════════════════════════════
            // BUTTONS
            // ═══════════════════════════════════
            Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                Gap(12.w),

                // Delete
                Expanded(
                  child: ElevatedButton(
                    onPressed: category.productCount > 0
                        ? null
                        : () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rejected,
                      disabledBackgroundColor:
                          AppColors.rejected.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
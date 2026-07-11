import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class PendingRequirementCard extends StatelessWidget {
  final RequirementModel requirement;

  const PendingRequirementCard({
    super.key,
    required this.requirement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to requirement detail
      },
      child: Container(
        width: 240.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════
            // TOP ROW
            // ═══════════════════
            Row(
              children: [
                // Product Image or Icon
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.pendingLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: requirement.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.network(
                            requirement.productImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Iconsax.box,
                          size: 18.sp,
                          color: AppColors.pending,
                        ),
                ),
                Gap(8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement.productName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        requirement.productCode,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pendingLight,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: AppColors.pending,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            Gap(12.h),

            // ═══════════════════
            // PRICE INFO
            // ═══════════════════
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceInfo(
                    label: 'Current',
                    value:
                        '₹${requirement.productCurrentPrice.toStringAsFixed(0)}',
                    color: AppColors.textSecondary,
                  ),
                  Container(
                    width: 1,
                    height: 28.h,
                    color: AppColors.border,
                  ),
                  _buildPriceInfo(
                    label: 'Demanded',
                    value:
                        '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
                    color: AppColors.pending,
                  ),
                ],
              ),
            ),

            Gap(10.h),

            // ═══════════════════
            // BOTTOM INFO
            // ═══════════════════
            Row(
              children: [
                Icon(
                  Iconsax.user,
                  size: 12.sp,
                  color: AppColors.textHint,
                ),
                Gap(4.w),
                Expanded(
                  child: Text(
                    requirement.traderName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeago.format(requirement.submittedAt),
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
    );
  }

  Widget _buildPriceInfo({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textHint,
          ),
        ),
        Gap(2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
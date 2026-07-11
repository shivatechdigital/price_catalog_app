import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentPriceUpdateCard extends StatelessWidget {
  final ProductModel product;

  const RecentPriceUpdateCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
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
          // Product Image
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: product.primaryImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.network(
                      product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Iconsax.box,
                        size: 20.sp,
                        color: AppColors.adminPrimary,
                      ),
                    ),
                  )
                : Icon(
                    Iconsax.box,
                    size: 20.sp,
                    color: AppColors.adminPrimary,
                  ),
          ),

          Gap(12.w),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(3.h),
                Row(
                  children: [
                    Text(
                      product.categoryName,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                    Gap(6.w),
                    Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: const BoxDecoration(
                        color: AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Gap(6.w),
                    Text(
                      timeago.format(product.updatedAt),
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

          // Price + Availability
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Gap(3.h),
              _buildAvailabilityBadge(product.availability),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(ProductAvailability availability) {
    final (color, text) = switch (availability) {
      ProductAvailability.inStock => (AppColors.approved, 'In Stock'),
      ProductAvailability.outOfStock => (AppColors.rejected, 'Out of Stock'),
      ProductAvailability.limitedStock => (AppColors.counter, 'Limited'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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
// TODO Implement this library.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';

class AdminProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const AdminProductListTile({
    super.key,
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
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 70.w,
                height: 70.w,
                child: product.primaryImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.primaryImage,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            Gap(12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Code
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildAvailabilityDot(product.availability),
                    ],
                  ),

                  Gap(3.h),

                  // Code + Category
                  Text(
                    '${product.productCode} • ${product.categoryName}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Gap(6.h),

                  // Price Row
                  Row(
                    children: [
                      // Selling Price
                      Text(
                        '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textHint,
                        ),
                      ),

                      Gap(8.w),

                      // Dealer Price
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.adminPrimary
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'D: ₹${product.currentPrice.dealerPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Gap(8.w),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.adminPrimary.withOpacity(0.06),
      child: Icon(
        Iconsax.box,
        color: AppColors.adminPrimary.withOpacity(0.3),
        size: 28.sp,
      ),
    );
  }

  Widget _buildAvailabilityDot(ProductAvailability availability) {
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
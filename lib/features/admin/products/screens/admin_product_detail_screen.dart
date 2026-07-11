import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/features/admin/products/screens/add_product_screen.dart';
import 'package:price_catalog_app/features/admin/products/screens/price_update_screen.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminProductDetailScreen extends ConsumerWidget {
  final ProductModel product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════
          // SLIVER APP BAR WITH IMAGES
          // ═══════════════════════════════════════
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: AppColors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            actions: [
              // Edit Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddProductScreen(product: product),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.all(8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.edit,
                        size: 16.sp,
                        color: AppColors.adminPrimary,
                      ),
                      Gap(4.w),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.adminPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(context, product),
            ),
          ),

          // ═══════════════════════════════════════
          // PRODUCT CONTENT
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  // Info Section
                  _buildInfoSection(product),
                  // Price Section
                  _buildPriceSection(context, product, ref),
                  // Price History
                  _buildPriceHistorySection(ref, product),
                  // Actions
                  _buildActionsSection(context, ref, product),
                  Gap(40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // IMAGE GALLERY
  // ═══════════════════════════════════════
  Widget _buildImageGallery(
      BuildContext context, ProductModel product) {
    if (product.images.isEmpty) {
      return Container(
        color: AppColors.adminPrimary.withOpacity(0.06),
        child: Icon(
          Iconsax.box,
          size: 80.sp,
          color: AppColors.adminPrimary.withOpacity(0.2),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullscreenGallery(context, product, 0),
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: product.images[index],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppColors.border,
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.adminPrimary.withOpacity(0.06),
              child: Icon(
                Iconsax.box,
                size: 60.sp,
                color: AppColors.adminPrimary.withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // FULLSCREEN GALLERY
  // ═══════════════════════════════════════
  void _showFullscreenGallery(
    BuildContext context,
    ProductModel product,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme:
                const IconThemeData(color: AppColors.white),
          ),
          body: PhotoViewGallery.builder(
            itemCount: product.images.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  product.images[index],
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            pageController:
                PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // INFO SECTION
  // ═══════════════════════════════════════
  Widget _buildInfoSection(ProductModel product) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + Availability
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  product.categoryName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildAvailabilityBadge(product.availability),
            ],
          ),

          Gap(10.h),

          // Product Name
          Text(
            product.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          Gap(6.h),

          // Code + Brand
          Row(
            children: [
              Icon(
                Iconsax.barcode,
                size: 14.sp,
                color: AppColors.textHint,
              ),
              Gap(4.w),
              Text(
                product.productCode,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textHint,
                ),
              ),
              Gap(12.w),
              Icon(
                Iconsax.medal,
                size: 14.sp,
                color: AppColors.textHint,
              ),
              Gap(4.w),
              Text(
                product.brand,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),

          if (product.description.isNotEmpty) ...[
            Gap(12.h),
            Text(
              product.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          Gap(12.h),

          // Unit + Updated
          Row(
            children: [
              _buildInfoChip(
                icon: Iconsax.weight,
                label: 'Per ${product.unit}',
              ),
              Gap(8.w),
              _buildInfoChip(
                icon: Iconsax.clock,
                label: timeago.format(product.updatedAt),
              ),
              Gap(8.w),
              _buildInfoChip(
                icon: Iconsax.eye,
                label: '${product.viewCount} views',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRICE SECTION
  // ═══════════════════════════════════════
  Widget _buildPriceSection(
    BuildContext context,
    ProductModel product,
    WidgetRef ref,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.adminGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Prices',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PriceUpdateScreen(product: product),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.edit,
                        size: 14.sp,
                        color: AppColors.white,
                      ),
                      Gap(4.w),
                      Text(
                        'Update',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Gap(16.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceItem(
                'Purchase',
                '₹${product.currentPrice.purchasePrice.toStringAsFixed(0)}',
                AppColors.white.withOpacity(0.7),
              ),
              _buildPriceItem(
                'Selling',
                '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                AppColors.white,
              ),
              _buildPriceItem(
                'Dealer',
                '₹${product.currentPrice.dealerPrice.toStringAsFixed(0)}',
                AppColors.traderAccent,
              ),
            ],
          ),

          if (product.currentPrice.minAcceptedPrice != null) ...[
            Gap(12.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.arrow_down,
                    size: 14.sp,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                  Gap(6.w),
                  Text(
                    'Min Accepted: ₹${product.currentPrice.minAcceptedPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.white.withOpacity(0.6),
          ),
        ),
        Gap(4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // PRICE HISTORY SECTION
  // ═══════════════════════════════════════
  Widget _buildPriceHistorySection(WidgetRef ref, ProductModel product) {
    final historyAsync = ref.watch(priceHistoryProvider(product.id));

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(12.h),
          historyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => Text(
              'Failed to load history',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            data: (history) {
              if (history.isEmpty) {
                return Center(
                  child: Text(
                    'No price changes yet',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: history.take(5).map((h) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: h.isPriceIncreased
                                ? AppColors.rejectedLight
                                : AppColors.approvedLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            h.isPriceIncreased
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 16.sp,
                            color: h.isPriceIncreased
                                ? AppColors.rejected
                                : AppColors.approved,
                          ),
                        ),
                        Gap(10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${h.oldSellingPrice.toStringAsFixed(0)} → ₹${h.newSellingPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                timeago.format(h.changedAt),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          h.isPriceIncreased
                              ? '+₹${h.sellingPriceDiff.toStringAsFixed(0)}'
                              : '₹${h.sellingPriceDiff.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: h.isPriceIncreased
                                ? AppColors.rejected
                                : AppColors.approved,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ACTIONS SECTION
  // ═══════════════════════════════════════
  Widget _buildActionsSection(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Product?'),
                    content: Text(
                      'Are you sure you want to delete "${product.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rejected,
                        ),
                        child: const Text(
                          'Delete',
                          style:
                              TextStyle(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(productRepositoryProvider)
                      .deleteProduct(product.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    CustomSnackbar.showSuccess(
                      context,
                      'Product deleted',
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.rejected),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(
                Iconsax.trash,
                size: 18.sp,
                color: AppColors.rejected,
              ),
              label: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.rejected,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PriceUpdateScreen(product: product),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              icon: Icon(
                Iconsax.money_recive,
                size: 18.sp,
                color: AppColors.white,
              ),
              label: Text(
                'Update Price',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(ProductAvailability availability) {
    final (color, text) = switch (availability) {
      ProductAvailability.inStock => (AppColors.approved, 'In Stock'),
      ProductAvailability.outOfStock =>
        (AppColors.rejected, 'Out of Stock'),
      ProductAvailability.limitedStock =>
        (AppColors.counter, 'Limited'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: AppColors.textHint),
          Gap(4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
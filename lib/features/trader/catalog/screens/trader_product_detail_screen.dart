import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/submit_requirement_screen.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class TraderProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const TraderProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<TraderProductDetailScreen> createState() =>
      _TraderProductDetailScreenState();
}

class _TraderProductDetailScreenState
    extends ConsumerState<TraderProductDetailScreen> {
  int _currentImageIndex = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Increment view count
    ref
        .read(productRepositoryProvider)
        .incrementViewCount(widget.product.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════
          // IMAGE SLIVER APP BAR
          // ═══════════════════════════════════════
          SliverAppBar(
            expandedHeight: 320.h,
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
                      color: Colors.black.withOpacity(0.12),
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
              // Share button
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Iconsax.share,
                    size: 18.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSection(product),
            ),
          ),

          // ═══════════════════════════════════════
          // CONTENT
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProductInfo(product),
                Gap(12.h),
                _buildPriceCard(product),
                Gap(12.h),
                if (product.description.isNotEmpty)
                  _buildDescriptionCard(product),
                Gap(12.h),
                _buildPriceHistoryCard(product),
                Gap(100.h),
              ],
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════
      // BOTTOM - SUBMIT REQUIREMENT BUTTON
      // ═══════════════════════════════════════
      bottomNavigationBar: _buildBottomBar(context, product),
    );
  }

  // ═══════════════════════════════════════
  // IMAGE SECTION
  // ═══════════════════════════════════════
  Widget _buildImageSection(ProductModel product) {
    if (product.images.isEmpty) {
      return Container(
        color: AppColors.traderPrimary.withOpacity(0.06),
        child: Icon(
          Iconsax.box,
          size: 80.sp,
          color: AppColors.traderPrimary.withOpacity(0.2),
        ),
      );
    }

    return Stack(
      children: [
        // Page view
        PageView.builder(
          controller: _pageController,
          itemCount: product.images.length,
          onPageChanged: (i) =>
              setState(() => _currentImageIndex = i),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullscreen(product, index),
              child: CachedNetworkImage(
                imageUrl: product.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            );
          },
        ),

        // Image indicators
        if (product.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: _currentImageIndex == i ? 20.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i
                        ? AppColors.traderPrimary
                        : AppColors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ),

        // Image count
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 5.h,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  size: 12.sp,
                  color: AppColors.white,
                ),
                Gap(4.w),
                Text(
                  '${_currentImageIndex + 1}/${product.images.length}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openFullscreen(ProductModel product, int index) {
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
            pageController: PageController(initialPage: index),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider:
                  CachedNetworkImageProvider(product.images[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRODUCT INFO
  // ═══════════════════════════════════════
  Widget _buildProductInfo(ProductModel product) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
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
                  color:
                      AppColors.traderPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  product.categoryName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.traderPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildAvailability(product.availability),
            ],
          ),

          Gap(10.h),

          // Name
          Text(
            product.name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          Gap(6.h),

          // Brand + Code
          Row(
            children: [
              Icon(
                Iconsax.medal,
                size: 14.sp,
                color: AppColors.textHint,
              ),
              Gap(4.w),
              Text(
                product.brand,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Gap(12.w),
              Icon(
                Iconsax.barcode,
                size: 14.sp,
                color: AppColors.textHint,
              ),
              Gap(4.w),
              Text(
                product.productCode,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          Gap(10.h),

          // Tags
          if (product.tags.isNotEmpty)
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: product.tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

          Gap(10.h),

          // Updated time
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: 12.sp,
                color: AppColors.textHint,
              ),
              Gap(4.w),
              Text(
                'Price updated ${timeago.format(product.updatedAt)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ═══════════════════════════════════════
  // PRICE CARD
  // ═══════════════════════════════════════
  Widget _buildPriceCard(ProductModel product) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.traderGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.traderPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Price',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'per ${product.unit}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          Gap(12.h),

          // Main Selling Price
          Text(
            '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),

          Gap(16.h),

          // Dealer Price
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.people,
                  size: 14.sp,
                  color: AppColors.white.withOpacity(0.8),
                ),
                Gap(6.w),
                Text(
                  'Dealer Price: ₹${product.currentPrice.dealerPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ═══════════════════════════════════════
  // DESCRIPTION
  // ═══════════════════════════════════════
  Widget _buildDescriptionCard(ProductModel product) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(10.h),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (product.specifications.isNotEmpty) ...[
            Gap(14.h),
            Text(
              'Specifications',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8.h),
            ...product.specifications.entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Text(
                      '${e.key}: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ═══════════════════════════════════════
  // PRICE HISTORY
  // ═══════════════════════════════════════
  Widget _buildPriceHistoryCard(ProductModel product) {
    final historyAsync =
        ref.watch(priceHistoryProvider(product.id));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
              'Failed to load',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            data: (history) {
              if (history.isEmpty) {
                return Center(
                  child: Text(
                    'No price history',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: history.take(3).map((h) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          h.isPriceIncreased
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 18.sp,
                          color: h.isPriceIncreased
                              ? AppColors.rejected
                              : AppColors.approved,
                        ),
                        Gap(8.w),
                        Expanded(
                          child: Text(
                            '₹${h.oldSellingPrice.toStringAsFixed(0)} → ₹${h.newSellingPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
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
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ═══════════════════════════════════════
  // BOTTOM BAR
  // ═══════════════════════════════════════
  Widget _buildBottomBar(
      BuildContext context, ProductModel product) {
    final isOutOfStock =
        product.availability == ProductAvailability.outOfStock;

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
      child: Row(
        children: [
          // Price display
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'per ${product.unit}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),

          Gap(16.w),

          // Submit button
          Expanded(
            child: SizedBox(
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SubmitRequirementScreen(
                              product: product,
                            ),
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? AppColors.border
                      : AppColors.traderPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  Iconsax.add_square,
                  color: AppColors.white,
                  size: 20.sp,
                ),
                label: Text(
                  isOutOfStock
                      ? 'Out of Stock'
                      : 'Submit Requirement',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(ProductAvailability availability) {
    final (color, text) = switch (availability) {
      ProductAvailability.inStock =>
        (AppColors.approved, 'In Stock'),
      ProductAvailability.outOfStock =>
        (AppColors.rejected, 'Out of Stock'),
      ProductAvailability.limitedStock =>
        (AppColors.counter, 'Limited'),
    };

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
}
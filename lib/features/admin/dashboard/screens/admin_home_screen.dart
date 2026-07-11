import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/admin/dashboard/widgets/admin_stat_card.dart';
import 'package:price_catalog_app/features/admin/dashboard/widgets/pending_requirement_card.dart';
import 'package:price_catalog_app/features/admin/dashboard/widgets/recent_price_update_card.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final pendingCountAsync = ref.watch(pendingRequirementsCountProvider);
    final pendingReqAsync = ref.watch(
      requirementsByStatusProvider(RequirementStatus.pending),
    );
    final unreadCount = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid))
        : const AsyncValue.data(0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsStreamProvider);
          ref.invalidate(pendingRequirementsCountProvider);
        },
        color: AppColors.adminPrimary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════════════════════════════════
            // APP BAR
            // ═══════════════════════════════════════
            SliverAppBar(
              expandedHeight: 120.h,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.adminPrimary,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(
                  context,
                  ref,
                  currentUser?.name ?? 'Admin',
                  unreadCount.asData?.value ?? 0,
                ),
              ),
              title: Text(
                'PriceCatalog',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Navigate to notifications
                      },
                      icon: Icon(
                        Iconsax.notification,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                    ),
                    if ((unreadCount.asData?.value ?? 0) > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.traderPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 8.w),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(20.h),

                  // ═══════════════════════════════════════
                  // STATS CARDS
                  // ═══════════════════════════════════════
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildStatsSection(
                      productsAsync,
                      pendingCountAsync,
                    ),
                  ),

                  Gap(24.h),

                  // ═══════════════════════════════════════
                  // PENDING REQUIREMENTS
                  // ═══════════════════════════════════════
                  _buildSectionHeader(
                    title: 'Pending Requirements',
                    icon: Iconsax.clock,
                    iconColor: AppColors.pending,
                    trailing: pendingReqAsync.asData?.value?.length ?? 0,
                  ),

                  Gap(12.h),

                  pendingReqAsync.when(
                    loading: () => _buildRequirementsShimmer(),
                    error: (_, __) => _buildErrorWidget(),
                    data: (requirements) {
                      if (requirements.isEmpty) {
                        return _buildEmptyRequirements();
                      }
                      return _buildPendingList(requirements);
                    },
                  ),

                  Gap(24.h),

                  // ═══════════════════════════════════════
                  // RECENT PRICE UPDATES
                  // ═══════════════════════════════════════
                  _buildSectionHeader(
                    title: 'Recent Price Updates',
                    icon: Iconsax.chart,
                    iconColor: AppColors.adminPrimary,
                  ),

                  Gap(12.h),

                  productsAsync.when(
                    loading: () => _buildProductsShimmer(),
                    error: (_, __) => _buildErrorWidget(),
                    data: (products) {
                      final recentProducts = products.take(5).toList();
                      if (recentProducts.isEmpty) {
                        return _buildEmptyProducts();
                      }
                      return _buildRecentProducts(recentProducts);
                    },
                  ),

                  Gap(100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String name,
    int unreadCount,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.adminGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  Gap(12.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome back! 👋',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.white.withOpacity(0.8),
                          ),
                        ),
                        Gap(2.h),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  if (unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.traderPrimary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.notification,
                            size: 14.sp,
                            color: AppColors.white,
                          ),
                          Gap(4.w),
                          Text(
                            '$unreadCount new',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATS SECTION
  // ═══════════════════════════════════════
  Widget _buildStatsSection(
    AsyncValue productsAsync,
    AsyncValue<int> pendingCountAsync,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Total Products',
                value: productsAsync.when(
                  data: (p) => '${p.length}',
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                icon: Iconsax.box,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                delay: 0,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AdminStatCard(
                title: 'Pending',
                value: pendingCountAsync.when(
                  data: (c) => '$c',
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                icon: Iconsax.clock,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                ),
                delay: 100,
              ),
            ),
          ],
        ),

        Gap(12.h),

        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Categories',
                value: '8',
                icon: Iconsax.category,
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                delay: 200,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AdminStatCard(
                title: 'Traders',
                value: '24',
                icon: Iconsax.people,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFC5C7D), Color(0xFF6A3093)],
                ),
                delay: 300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    int? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: iconColor),
          ),
          Gap(10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null && trailing > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.pending.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$trailing pending',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.pending,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PENDING REQUIREMENTS LIST
  // ═══════════════════════════════════════
  Widget _buildPendingList(List<RequirementModel> requirements) {
    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: requirements.length,
        separatorBuilder: (_, __) => Gap(12.w),
        itemBuilder: (context, index) {
          return PendingRequirementCard(
            requirement: requirements[index],
          ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // RECENT PRODUCTS
  // ═══════════════════════════════════════
  Widget _buildRecentProducts(List products) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: products
            .map((product) => RecentPriceUpdateCard(product: product)
                .animate()
                .fadeIn(
                  delay: Duration(
                    milliseconds: products.indexOf(product) * 100,
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // EMPTY STATES
  // ═══════════════════════════════════════
  Widget _buildEmptyRequirements() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.approvedLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.approved.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 40.sp,
              color: AppColors.approved,
            ),
            Gap(8.h),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.approved,
              ),
            ),
            Gap(4.h),
            Text(
              'No pending requirements',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Text(
            'No products yet. Add your first product!',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.rejectedLight,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.rejected,
              size: 20.sp,
            ),
            Gap(8.w),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.rejected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHIMMER LOADERS
  // ═══════════════════════════════════════
  Widget _buildRequirementsShimmer() {
    return SizedBox(
      height: 160.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 3,
        separatorBuilder: (_, __) => Gap(12.w),
        itemBuilder: (_, __) => ShimmerLoading(
          width: 240.w,
          height: 150.h,
          borderRadius: 16.r,
        ),
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ShimmerLoading(
              width: double.infinity,
              height: 72.h,
              borderRadius: 12.r,
            ),
          ),
        ),
      ),
    );
  }
}
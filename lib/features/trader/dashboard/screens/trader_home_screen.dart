import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/trader/catalog/screens/trader_catalog_screen.dart';
import 'package:price_catalog_app/features/trader/dashboard/screens/trader_dashboard_screen.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/trader_requirements_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';
import 'package:timeago/timeago.dart' as timeago;

class TraderHomeScreen extends ConsumerWidget {
  const TraderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    final myRequirementsAsync = currentUser != null
        ? ref.watch(traderRequirementsProvider(currentUser.uid))
        : const AsyncValue.data(<RequirementModel>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsStreamProvider);
        },
        color: AppColors.traderPrimary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════════════════════════════════
            // APP BAR
            // ═══════════════════════════════════════
            SliverAppBar(
              expandedHeight: 190.h,
              pinned: true,
              backgroundColor: AppColors.traderPrimary,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(
                  context,
                  ref,
                  currentUser?.name ?? 'Trader',
                  currentUser?.businessName ?? '',
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
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(20.h),

                  // ═══════════════════════════════════════
                  // QUICK STATS
                  // ═══════════════════════════════════════
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w),
                    child: myRequirementsAsync.when(
                      loading: () => _buildStatsShimmer(),
                      error: (_, __) => const SizedBox(),
                      data: (requirements) =>
                          _buildQuickStats(requirements),
                    ),
                  ),

                  Gap(24.h),

                  // ═══════════════════════════════════════
                  // QUICK ACTIONS
                  // ═══════════════════════════════════════
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildQuickActions(context, ref),
                  ),

                  Gap(24.h),

                  // ═══════════════════════════════════════
                  // RECENT REQUIREMENTS
                  // ═══════════════════════════════════════
                  _buildSectionHeader(
                    title: 'My Recent Deals',
                    icon: Iconsax.document,
                    onViewAll: () {
                      ref
                          .read(traderNavIndexProvider.notifier)
                          .state = 2;
                    },
                  ),

                  Gap(12.h),

                  myRequirementsAsync.when(
                    loading: () => _buildReqShimmer(),
                    error: (_, __) => const SizedBox(),
                    data: (requirements) {
                      if (requirements.isEmpty) {
                        return _buildEmptyRequirements(
                            context, ref);
                      }
                      return _buildRecentRequirements(
                        requirements.take(3).toList(),
                      );
                    },
                  ),

                  Gap(24.h),

                  // ═══════════════════════════════════════
                  // RECENT PRODUCTS
                  // ═══════════════════════════════════════
                  _buildSectionHeader(
                    title: 'Latest Products',
                    icon: Iconsax.box,
                    onViewAll: () {
                      ref
                          .read(traderNavIndexProvider.notifier)
                          .state = 1;
                    },
                  ),

                  Gap(12.h),

                  productsAsync.when(
                    loading: () => _buildProductsShimmer(),
                    error: (_, __) => const SizedBox(),
                    data: (products) {
                      final recent = products.take(5).toList();
                      return _buildRecentProducts(
                          context, recent);
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
    String businessName,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.traderGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
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
                            : 'T',
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name! 👋',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        Gap(2.h),
                        Text(
                          businessName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                AppColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification icon
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.notification,
                      size: 20.sp,
                      color: AppColors.white,
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
  // QUICK STATS
  // ═══════════════════════════════════════
  Widget _buildQuickStats(List<RequirementModel> requirements) {
    final pending = requirements
        .where((r) => r.status == RequirementStatus.pending)
        .length;
    final approved = requirements
        .where((r) => r.status == RequirementStatus.approved)
        .length;
    final total = requirements.length;

    return Row(
      children: [
        Expanded(
          child: _TraderStatCard(
            title: 'Total Deals',
            value: '$total',
            icon: Iconsax.document,
            color: AppColors.adminPrimary,
            delay: 0,
          ),
        ),
        Gap(10.w),
        Expanded(
          child: _TraderStatCard(
            title: 'Pending',
            value: '$pending',
            icon: Iconsax.clock,
            color: AppColors.traderPrimary,
            delay: 100,
          ),
        ),
        Gap(10.w),
        Expanded(
          child: _TraderStatCard(
            title: 'Approved',
            value: '$approved',
            icon: Icons.check_circle_rounded,
            color: AppColors.approved,
            delay: 200,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _QuickActionBtn(
                icon: Iconsax.box,
                label: 'Browse\nProducts',
                color: AppColors.adminPrimary,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 1,
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _QuickActionBtn(
                icon: Iconsax.add_square,
                label: 'New\nRequirement',
                color: AppColors.traderPrimary,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 1,
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _QuickActionBtn(
                icon: Iconsax.document_upload,
                label: 'Share\nCatalog',
                color: AppColors.approved,
                onTap: () {},
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
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: AppColors.traderPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 15.sp,
              color: AppColors.traderPrimary,
            ),
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
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.traderPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // RECENT REQUIREMENTS
  // ═══════════════════════════════════════
  Widget _buildRecentRequirements(
      List<RequirementModel> requirements) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: requirements
            .map(
              (req) => _TraderReqCard(requirement: req)
                  .animate()
                  .fadeIn(
                    delay: Duration(
                      milliseconds:
                          requirements.indexOf(req) * 80,
                    ),
                  ),
            )
            .toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // RECENT PRODUCTS
  // ═══════════════════════════════════════
  Widget _buildRecentProducts(BuildContext context, List products) {
    return SizedBox(
      height: 200.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: products.length,
        separatorBuilder: (_, __) => Gap(12.w),
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 150.w,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14.r),
                    ),
                    child: Container(
                      height: 100.h,
                      width: double.infinity,
                      color: AppColors.traderPrimary
                          .withOpacity(0.08),
                      child: Icon(
                        Iconsax.box,
                        size: 36.sp,
                        color: AppColors.traderPrimary
                            .withOpacity(0.3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap(4.h),
                        Text(
                          '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}/${product.unit}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.traderPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 80),
                duration: 300.ms,
              );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // EMPTY REQUIREMENTS
  // ═══════════════════════════════════════
  Widget _buildEmptyRequirements(
      BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.traderPrimary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.traderPrimary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Iconsax.document_forward_copy,
              size: 40.sp,
              color: AppColors.traderPrimary,
            ),
            Gap(10.h),
            Text(
              'No deals yet!',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(6.h),
            Text(
              'Browse products and submit your first requirement',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            GestureDetector(
              onTap: () => ref
                  .read(traderNavIndexProvider.notifier)
                  .state = 1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.traderGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Browse Products',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SHIMMERS
  Widget _buildStatsShimmer() {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 10.w : 0),
            child: ShimmerLoading(
              width: double.infinity,
              height: 80.h,
              borderRadius: 14.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReqShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: ShimmerLoading(
              width: double.infinity,
              height: 80.h,
              borderRadius: 12.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return SizedBox(
      height: 200.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 4,
        separatorBuilder: (_, __) => Gap(12.w),
        itemBuilder: (_, __) => ShimmerLoading(
          width: 150.w,
          height: 200.h,
          borderRadius: 14.r,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER STAT CARD
// ═══════════════════════════════════════
class _TraderStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _TraderStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          Gap(10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delay),
        );
  }
}

// ═══════════════════════════════════════
// QUICK ACTION BUTTON
// ═══════════════════════════════════════
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 16.h,
          horizontal: 8.w,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 22.sp,
                color: AppColors.white,
              ),
            ),
            Gap(8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER REQUIREMENT CARD (Mini)
// ═══════════════════════════════════════
class _TraderReqCard extends StatelessWidget {
  final RequirementModel requirement;

  const _TraderReqCard({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (requirement.status) {
      RequirementStatus.pending => (
          AppColors.pending,
          Iconsax.clock,
          'Pending'
        ),
      RequirementStatus.approved => (
          AppColors.approved,
          Icons.check_circle_rounded,
          'Approved'
        ),
      RequirementStatus.rejected => (
          AppColors.rejected,
          Icons.cancel_rounded,
          'Rejected'
        ),
      RequirementStatus.counterOffer => (
          AppColors.counter,
          Icons.compare_arrows_rounded,
          'Counter Offer'
        ),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),

          Gap(12.w),

          // Info
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
                Gap(3.h),
                Text(
                  '${requirement.customerName} • ${requirement.customerCity}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Price + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Gap(4.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
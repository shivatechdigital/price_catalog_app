import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/order_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/admin/orders/screens/admin_order_detail_screen.dart';
import 'package:price_catalog_app/features/admin/requirements/screens/admin_requirement_detail_screen.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/requirement_card.dart';
import 'package:price_catalog_app/providers/order_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';

class AdminRequirementsScreen extends ConsumerStatefulWidget {
  const AdminRequirementsScreen({super.key});

  @override
  ConsumerState<AdminRequirementsScreen> createState() =>
      _AdminRequirementsScreenState();
}

class _AdminRequirementsScreenState
    extends ConsumerState<AdminRequirementsScreen>
    with SingleTickerProviderStateMixin {
  // ✅ FIX: 6 tabs - added 'Orders' tab
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<
      ({
        String label,
        RequirementStatus? status,
        Color color,
        bool isOrdersTab,
      })> _tabs = [
    (
      label: 'Orders',
      status: null,
      color: AppColors.adminPrimary,
      isOrdersTab: true,
    ),
    (
      label: 'All Req',
      status: null,
      color: AppColors.adminPrimary,
      isOrdersTab: false,
    ),
    (
      label: 'Pending',
      status: RequirementStatus.pending,
      color: AppColors.pending,
      isOrdersTab: false,
    ),
    (
      label: 'Approved',
      status: RequirementStatus.approved,
      color: AppColors.approved,
      isOrdersTab: false,
    ),
    (
      label: 'Rejected',
      status: RequirementStatus.rejected,
      color: AppColors.rejected,
      isOrdersTab: false,
    ),
    (
      label: 'Counter',
      status: RequirementStatus.counterOffer,
      color: AppColors.counter,
      isOrdersTab: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ FIX: length = 6 (tabs count)
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pending orders count for badge
    final pendingOrdersCount = ref.watch(
      pendingOrdersCountProvider,
    ).when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final pendingReqCount = ref.watch(
      requirementsByStatusProvider(RequirementStatus.pending),
    ).when(
      data: (requirements) => requirements.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: innerBoxIsScrolled ? 2 : 0,
            title: Text(
              'Requirements & Orders',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // Future: filter by trader
                },
                icon: Icon(
                  Iconsax.filter,
                  size: 22.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(112.h),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildTabBar(
                    pendingOrdersCount,
                    pendingReqCount,
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
            // ✅ Orders Tab
            if (tab.isOrdersTab) {
              return _OrdersTabView(
                searchQuery: _searchQuery,
              );
            }
            // ✅ Requirements Tabs
            return _RequirementTabView(
              status: tab.status,
              searchQuery: _searchQuery,
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by product, trader, customer...',
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 20.sp,
            color: AppColors.textHint,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.textHint,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════
  Widget _buildTabBar(
    int pendingOrdersCount,
    int pendingReqCount,
  ) {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(),
        tabs: _tabs.asMap().entries.map((entry) {
          final tab = entry.value;
          return _buildTab(
            label: tab.label,
            color: tab.color,
            badgeCount: tab.isOrdersTab
                ? pendingOrdersCount
                : tab.label == 'Pending'
                    ? pendingReqCount
                    : 0,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required Color color,
    int badgeCount = 0,
  }) {
    return Tab(
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final index =
              _tabs.indexWhere((t) => t.label == label);
          final isSelected = _tabController.index == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 6.h,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color:
                        isSelected ? color : AppColors.textHint,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -8,
                    right: -12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rejected,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        badgeCount > 9
                            ? '9+'
                            : '$badgeCount',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// ORDERS TAB VIEW (Multi-product orders)
// ═══════════════════════════════════════
class _OrdersTabView extends ConsumerWidget {
  final String searchQuery;

  const _OrdersTabView({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return ordersAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52.sp,
              color: AppColors.rejected,
            ),
            Gap(16.h),
            const Text('Failed to load orders'),
            Gap(12.h),
            ElevatedButton(
              onPressed: () => ref.invalidate(allOrdersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orders) {
        // Filter by search
        final filtered = searchQuery.isEmpty
            ? orders
            : orders.where((o) {
                final q = searchQuery.toLowerCase();
                return o.traderName
                        .toLowerCase()
                        .contains(q) ||
                    o.customerName
                        .toLowerCase()
                        .contains(q) ||
                    o.customerBusinessName
                        .toLowerCase()
                        .contains(q) ||
                    o.items.any(
                      (i) => i.productName
                          .toLowerCase()
                          .contains(q),
                    );
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary
                        .withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.shopping_cart,
                    size: 40.sp,
                    color: AppColors.adminPrimary,
                  ),
                ),
                Gap(16.h),
                Text(
                  searchQuery.isNotEmpty
                      ? 'No orders found'
                      : 'No Orders Yet',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Multi-product orders will appear here',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(allOrdersProvider),
          color: AppColors.adminPrimary,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16.w,
              16.h,
              16.w,
              80.h,
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Gap(12.h),
            itemBuilder: (context, index) {
              final order = filtered[index];
              return _OrderSummaryCard(
                order: order,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminOrderDetailScreen(
                      order: order,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(
                      milliseconds: index * 60,
                    ),
                    duration: 300.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 4,
      separatorBuilder: (_, __) => Gap(12.h),
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: 180.h,
        borderRadius: 16.r,
      ),
    );
  }
}

// ═══════════════════════════════════════
// ORDER SUMMARY CARD (For Admin List)
// ═══════════════════════════════════════
class _OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderSummaryCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.orderStatus) {
      OrderStatus.pending => AppColors.pending,
      OrderStatus.approved => AppColors.approved,
      OrderStatus.rejected => AppColors.rejected,
      OrderStatus.partial => AppColors.counter,
      OrderStatus.counterOffer => AppColors.counter,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: statusColor.withOpacity(0.25),
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
            // ─── Status Header ────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      order.statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Gap(8.w),
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.totalItems} Products',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Main Content ─────────────────────────────
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                children: [
                  // Trader + Customer
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.people,
                                  size: 12.sp,
                                  color: AppColors.adminPrimary,
                                ),
                                Gap(4.w),
                                Text(
                                  order.traderName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        AppColors.adminPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Gap(4.h),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.shop,
                                  size: 12.sp,
                                  color: AppColors.traderPrimary,
                                ),
                                Gap(4.w),
                                Text(
                                  '${order.customerName} • ${order.customerCity}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),

                  Gap(12.h),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: Row(
                      children: [
                        if (order.approvedCount > 0)
                          Expanded(
                            flex: order.approvedCount,
                            child: Container(
                              height: 6.h,
                              color: AppColors.approved,
                            ),
                          ),
                        if (order.counterCount > 0)
                          Expanded(
                            flex: order.counterCount,
                            child: Container(
                              height: 6.h,
                              color: AppColors.counter,
                            ),
                          ),
                        if (order.rejectedCount > 0)
                          Expanded(
                            flex: order.rejectedCount,
                            child: Container(
                              height: 6.h,
                              color: AppColors.rejected,
                            ),
                          ),
                        if (order.pendingCount > 0)
                          Expanded(
                            flex: order.pendingCount,
                            child: Container(
                              height: 6.h,
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Gap(8.h),

                  // Count Summary
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _statBadge(
                        '${order.approvedCount}',
                        'Approved',
                        AppColors.approved,
                        AppColors.approvedLight,
                      ),
                      _statBadge(
                        '${order.counterCount}',
                        'Counter',
                        AppColors.counter,
                        AppColors.counterLight,
                      ),
                      _statBadge(
                        '${order.rejectedCount}',
                        'Rejected',
                        AppColors.rejected,
                        AppColors.rejectedLight,
                      ),
                      _statBadge(
                        '${order.pendingCount}',
                        'Pending',
                        AppColors.textSecondary,
                        AppColors.background,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Footer ───────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.money,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                      Gap(4.w),
                      Text(
                        'Total: ₹${order.totalOrderValue.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 12.sp,
                        color: AppColors.textHint,
                      ),
                      Gap(4.w),
                      Text(
                        _formatDate(order.submittedAt),
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
          ],
        ),
      ),
    );
  }

  Widget _statBadge(
    String count,
    String label,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════
// REQUIREMENT TAB VIEW (Single product)
// ═══════════════════════════════════════
class _RequirementTabView extends ConsumerWidget {
  final RequirementStatus? status;
  final String searchQuery;

  const _RequirementTabView({
    required this.status,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementsAsync = status != null
        ? ref.watch(requirementsByStatusProvider(status!))
        : ref.watch(allRequirementsProvider);

    return requirementsAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildError(context, ref),
      data: (requirements) {
        // Filter by search
        final filtered = searchQuery.isEmpty
            ? requirements
            : requirements.where((r) {
                final q = searchQuery.toLowerCase();
                return r.productName
                        .toLowerCase()
                        .contains(q) ||
                    r.traderName.toLowerCase().contains(q) ||
                    r.customerName.toLowerCase().contains(q) ||
                    r.customerBusinessName
                        .toLowerCase()
                        .contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return _buildEmpty(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allRequirementsProvider);
          },
          color: AppColors.adminPrimary,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16.w,
              16.h,
              16.w,
              80.h,
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Gap(12.h),
            itemBuilder: (context, index) {
              return RequirementCard(
                requirement: filtered[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminRequirementDetailScreen(
                      requirement: filtered[index],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(
                      milliseconds: index * 60,
                    ),
                    duration: 300.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      separatorBuilder: (_, __) => Gap(12.h),
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: 160.h,
        borderRadius: 16.r,
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 52.sp,
            color: AppColors.rejected,
          ),
          Gap(16.h),
          Text(
            'Failed to load requirements',
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(12.h),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(allRequirementsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(RequirementStatus? status) {
    final (icon, title, subtitle) = switch (status) {
      RequirementStatus.pending => (
          Iconsax.clock,
          'No Pending Requirements',
          'All requirements have been reviewed',
        ),
      RequirementStatus.approved => (
          Icons.check_circle_rounded,
          'No Approved Deals',
          'Approved requirements will appear here',
        ),
      RequirementStatus.rejected => (
          Icons.cancel_rounded,
          'No Rejected Requirements',
          'Rejected requirements will appear here',
        ),
      RequirementStatus.counterOffer => (
          Icons.compare_arrows_rounded,
          'No Counter Offers',
          'Counter offers will appear here',
        ),
      _ => (
          Iconsax.document,
          'No Requirements Yet',
          'Trader requirements will appear here',
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88.w,
            height: 88.w,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40.sp,
              color: AppColors.adminPrimary,
            ),
          ),
          Gap(16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(6.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
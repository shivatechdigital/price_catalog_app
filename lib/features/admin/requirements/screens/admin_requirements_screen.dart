import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/admin/requirements/screens/admin_requirement_detail_screen.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/requirement_card.dart';
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
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<({String label, RequirementStatus? status, Color color})>
      _tabs = [
    (label: 'All', status: null, color: AppColors.adminPrimary),
    (
      label: 'Pending',
      status: RequirementStatus.pending,
      color: AppColors.pending
    ),
    (
      label: 'Approved',
      status: RequirementStatus.approved,
      color: AppColors.approved
    ),
    (
      label: 'Rejected',
      status: RequirementStatus.rejected,
      color: AppColors.rejected
    ),
    (
      label: 'Counter',
      status: RequirementStatus.counterOffer,
      color: AppColors.counter
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Requirements',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              // Filter by trader
              IconButton(
                onPressed: () {},
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
                  // Search
                  _buildSearchBar(),
                  // Tabs
                  _buildTabBar(),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
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
  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        labelPadding:
            EdgeInsets.symmetric(horizontal: 4.w),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(),
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: _tabs.asMap().entries.map((entry) {
          final tab = entry.value;
          return _buildTab(tab.label, tab.color);
        }).toList(),
      ),
    );
  }

  Widget _buildTab(String label, Color color) {
    return Tab(
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final index = _tabs.indexWhere((t) => t.label == label);
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
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textHint,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// REQUIREMENT TAB VIEW
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
                return r.productName.toLowerCase().contains(q) ||
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
            padding:
                EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
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
                    delay: Duration(milliseconds: index * 60),
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
            size: 52,
            color: AppColors.rejected,
          ),
          const Gap(16),
          const Text('Failed to load requirements'),
          const Gap(12),
          ElevatedButton(
            onPressed: () => ref.invalidate(allRequirementsProvider),
            child: const Text('Retry'),
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
          'All requirements have been reviewed'
        ),
      RequirementStatus.approved => (
          Icons.check_circle_rounded,
          'No Approved Deals',
          'Approved requirements will appear here'
        ),
      RequirementStatus.rejected => (
          Icons.cancel_rounded,
          'No Rejected Requirements',
          'Rejected requirements will appear here'
        ),
      RequirementStatus.counterOffer => (
          Icons.compare_arrows_rounded,
          'No Counter Offers',
          'Counter offers will appear here'
        ),
      _ => (
          Iconsax.document,
          'No Requirements Yet',
          'Trader requirements will appear here'
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
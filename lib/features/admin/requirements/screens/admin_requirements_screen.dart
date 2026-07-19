import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/requirement_export_service.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/admin/requirements/screens/admin_requirement_detail_screen.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/requirement_card.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
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

  final List<({String label, RequirementStatus? status, Color color})> _tabs = [
    (label: 'All', status: null, color: AppColors.adminPrimary),
    (
      label: 'Pending',
      status: RequirementStatus.pending,
      color: AppColors.pending,
    ),
    (
      label: 'Approved',
      status: RequirementStatus.approved,
      color: AppColors.approved,
    ),
    (
      label: 'Rejected',
      status: RequirementStatus.rejected,
      color: AppColors.rejected,
    ),
    (
      label: 'Counter',
      status: RequirementStatus.counterOffer,
      color: AppColors.counter,
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
    final pendingReqCount = ref
        .watch(requirementsByStatusProvider(RequirementStatus.pending))
        .when(
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
              'Requirements',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await _exportCurrentView();
                },
                icon: Icon(
                  Iconsax.export,
                  size: 22.sp,
                  color: AppColors.adminPrimary,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(112.h),
              child: Column(
                children: [_buildSearchBar(), _buildTabBar(pendingReqCount)],
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

  Future<void> _exportCurrentView() async {
    final selectedStatus = _tabs[_tabController.index].status;
    final requirements = selectedStatus == null
        ? await ref.read(allRequirementsProvider.future)
        : await ref.read(requirementsByStatusProvider(selectedStatus).future);

    final filtered = requirements.where((requirement) {
      if (_searchQuery.isEmpty) return true;
      final search = _searchQuery.toLowerCase();
      return requirement.productName.toLowerCase().contains(search) ||
          requirement.traderName.toLowerCase().contains(search) ||
          requirement.customerName.toLowerCase().contains(search) ||
          requirement.customerBusinessName.toLowerCase().contains(search);
    }).toList();

    if (!mounted) return;
    if (filtered.isEmpty) {
      CustomSnackbar.showInfo(context, 'No matching requirements to export.');
      return;
    }

    final range = await showModalBottomSheet<ExportRange>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export current view',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Gap(12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Today', style: TextStyle(fontSize: 15.sp)),
                onTap: () => Navigator.pop(context, ExportRange.today),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('This Week', style: TextStyle(fontSize: 15.sp)),
                onTap: () => Navigator.pop(context, ExportRange.thisWeek),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('This Year', style: TextStyle(fontSize: 15.sp)),
                onTap: () => Navigator.pop(context, ExportRange.thisYear),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Custom Range', style: TextStyle(fontSize: 15.sp)),
                onTap: () => Navigator.pop(context, ExportRange.custom),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('All Records', style: TextStyle(fontSize: 15.sp)),
                onTap: () => Navigator.pop(context, ExportRange.all),
              ),
            ],
          ),
        );
      },
    );

    if (range == null) return;

    DateTimeRange? dateRange;
    if (range == ExportRange.custom) {
      dateRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
      );
      if (dateRange == null) return;
    }

    final success = await RequirementExportService.shareRequirementsExport(
      filtered,
      range: range,
      customStart: dateRange?.start,
      customEnd: dateRange?.end,
      fileNamePrefix: 'admin_requirements_view',
    );

    if (!mounted) return;
    CustomSnackbar.showSuccess(
      context,
      success ? 'Export ready to share.' : 'Unable to export right now.',
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
  Widget _buildTabBar(int pendingReqCount) {
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
            badgeCount: tab.label == 'Pending' ? pendingReqCount : 0,
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
          final index = _tabs.indexWhere((t) => t.label == label);
          final isSelected = _tabController.index == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
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
                    color: isSelected ? color : AppColors.textHint,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
                        badgeCount > 9 ? '9+' : '$badgeCount',
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
// REQUIREMENT TAB VIEW
// ═══════════════════════════════════════
class _RequirementTabView extends ConsumerWidget {
  final RequirementStatus? status;
  final String searchQuery;

  const _RequirementTabView({required this.status, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementsAsync = status != null
        ? ref.watch(requirementsByStatusProvider(status!))
        : ref.watch(allRequirementsProvider);

    return requirementsAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildError(context, ref),
      data: (requirements) {
        // Filter by search (matches across all items)
        final filtered = searchQuery.isEmpty
            ? requirements
            : requirements.where((r) {
                final q = searchQuery.toLowerCase();
                return r.traderName.toLowerCase().contains(q) ||
                    r.customerName.toLowerCase().contains(q) ||
                    r.customerBusinessName.toLowerCase().contains(q) ||
                    r.items.any((i) => i.productName.toLowerCase().contains(q));
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
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
            size: 52.sp,
            color: AppColors.rejected,
          ),
          Gap(16.h),
          Text(
            'Failed to load requirements',
            style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary),
          ),
          Gap(12.h),
          ElevatedButton(
            onPressed: () => ref.invalidate(allRequirementsProvider),
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
            child: Icon(icon, size: 40.sp, color: AppColors.adminPrimary),
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
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

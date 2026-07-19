import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/requirement_export_service.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/trader_requirement_detail_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';
import 'package:timeago/timeago.dart' as timeago;

class TraderRequirementsScreen extends ConsumerStatefulWidget {
  const TraderRequirementsScreen({super.key});

  @override
  ConsumerState<TraderRequirementsScreen> createState() =>
      _TraderRequirementsScreenState();
}

class _TraderRequirementsScreenState
    extends ConsumerState<TraderRequirementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<({String label, RequirementStatus? status, Color color})> _tabs = [
    (label: 'All', status: null, color: AppColors.traderPrimary),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: innerBoxIsScrolled ? 2 : 0,
            title: Text(
              'My Deals',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  if (currentUser == null) return;
                  await _exportCurrentView(currentUser.uid);
                },
                icon: Icon(
                  Iconsax.export,
                  size: 22.sp,
                  color: AppColors.traderPrimary,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48.h),
              child: _buildTabBar(),
            ),
          ),
        ],
        body: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return _TraderRequirementTabView(
                    traderId: currentUser.uid,
                    status: tab.status,
                  );
                }).toList(),
              ),
      ),
    );
  }

  Future<void> _exportCurrentView(String traderId) async {
    final selectedStatus = _tabs[_tabController.index].status;
    final requirements = selectedStatus == null
        ? await ref.read(traderRequirementsProvider(traderId).future)
        : await ref.read(
            traderRequirementsByStatusProvider((
              traderId: traderId,
              status: selectedStatus,
            )).future,
          );

    if (!mounted) return;
    if (requirements.isEmpty) {
      CustomSnackbar.showInfo(context, 'No deals found to export.');
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
                'Export my deals',
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
      requirements,
      range: range,
      customStart: dateRange?.start,
      customEnd: dateRange?.end,
      fileNamePrefix: 'trader_requirements',
    );

    if (!mounted) return;
    CustomSnackbar.showSuccess(
      context,
      success ? 'Export ready to share.' : 'Unable to export right now.',
    );
  }

  Widget _buildTabBar() {
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
          return Tab(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isSelected = _tabController.index == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tab.color.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? tab.color : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isSelected ? tab.color : AppColors.textHint,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TAB VIEW
// ═══════════════════════════════════════
class _TraderRequirementTabView extends ConsumerWidget {
  final String traderId;
  final RequirementStatus? status;

  const _TraderRequirementTabView({
    required this.traderId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementsAsync = status != null
        ? ref.watch(
            traderRequirementsByStatusProvider((
              traderId: traderId,
              status: status!,
            )),
          )
        : ref.watch(traderRequirementsProvider(traderId));

    return requirementsAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => const Center(child: Text('Failed to load')),
      data: (requirements) {
        if (requirements.isEmpty) {
          return _buildEmpty(status);
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
          itemCount: requirements.length,
          separatorBuilder: (_, __) => Gap(12.h),
          itemBuilder: (context, index) {
            return _TraderRequirementCard(
                  requirement: requirements[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TraderRequirementDetailScreen(
                        requirement: requirements[index],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: index * 60),
                  duration: 300.ms,
                )
                .slideY(begin: 0.05, end: 0);
          },
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
        height: 130.h,
        borderRadius: 14.r,
      ),
    );
  }

  Widget _buildEmpty(RequirementStatus? status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.document, size: 52, color: AppColors.textHint),
          const Gap(16),
          Text(
            status == null
                ? 'No requirements yet'
                : 'No ${status.name} requirements',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER REQUIREMENT CARD
// ═══════════════════════════════════════
class _TraderRequirementCard extends StatelessWidget {
  final RequirementModel requirement;
  final VoidCallback onTap;

  const _TraderRequirementCard({
    required this.requirement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counterPrice = requirement.counterPrice;
    final (color, icon, label) = switch (requirement.status) {
      RequirementStatus.pending => (
        AppColors.pending,
        Iconsax.clock,
        'Pending',
      ),
      RequirementStatus.approved => (
        AppColors.approved,
        Icons.check_circle_rounded,
        'Approved ✅',
      ),
      RequirementStatus.rejected => (
        AppColors.rejected,
        Icons.cancel_rounded,
        'Rejected ❌',
      ),
      RequirementStatus.counterOffer => (
        AppColors.counter,
        Icons.compare_arrows_rounded,
        'Counter Offer 🔄',
      ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.25)),
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
            // Status Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 14.sp, color: color),
                  Gap(6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeago.format(requirement.submittedAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                children: [
                  // Product + Customer
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: requirement.productImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Image.network(
                                      requirement.productImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Iconsax.box,
                                        size: 20.sp,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Iconsax.box,
                                    size: 20.sp,
                                    color: AppColors.textHint,
                                  ),
                          ),
                          if (requirement.items.length > 1)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.traderPrimary,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '${requirement.items.length}',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requirement.items.length > 1
                                  ? '${requirement.items.length} Products'
                                  : requirement.productName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Gap(3.h),
                            Text(
                              requirement.items.length > 1
                                  ? _productSummary(requirement.items)
                                  : '${requirement.customerName} • ${requirement.customerCity}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),

                  Gap(12.h),

                  // Price + Qty
                  Row(
                    children: [
                      _InfoChip(
                        label: requirement.items.length > 1
                            ? '${requirement.items.length} items'
                            : '${requirement.quantity} ${requirement.unit}',
                        icon: Iconsax.weight,
                        color: AppColors.textSecondary,
                      ),
                      Gap(8.w),
                      _InfoChip(
                        label:
                            '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
                        icon: Iconsax.money_recive,
                        color: AppColors.pending,
                      ),
                      Gap(8.w),
                      _InfoChip(
                        label: _getPaymentShort(requirement.paymentType),
                        icon: Iconsax.money,
                        color: AppColors.adminPrimary,
                      ),
                    ],
                  ),

                  // Counter offer action
                  if (requirement.isCounterOffer && counterPrice != null) ...[
                    Gap(10.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.counterLight,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.counter.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.compare_arrows_rounded,
                            size: 14.sp,
                            color: AppColors.counter,
                          ),
                          Gap(6.w),
                          Expanded(
                            child: Text(
                              'Counter: ₹${counterPrice.toStringAsFixed(0)} — Tap to respond',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.counter,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Admin note
                  if (requirement.adminNote != null &&
                      requirement.adminNote!.isNotEmpty) ...[
                    Gap(8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.note_text,
                            size: 13.sp,
                            color: AppColors.textHint,
                          ),
                          Gap(6.w),
                          Expanded(
                            child: Text(
                              requirement.adminNote!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentShort(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => 'Full Cash',
      PaymentType.partialPayment => 'Partial',
      PaymentType.credit => 'Credit',
    };
  }

  String _productSummary(List<RequirementItemModel> items) {
    if (items.length <= 2) {
      return items.map((i) => i.productName).join(' • ');
    }
    return '${items[0].productName} • +${items.length - 1} more';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          Gap(4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

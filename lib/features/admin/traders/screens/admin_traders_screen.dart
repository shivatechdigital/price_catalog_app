import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/user_model.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:price_catalog_app/shared/widgets/shimmer_loading.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════
// TRADERS PROVIDER
// ═══════════════════════════════════════
final tradersStreamProvider =
    StreamProvider<List<UserModel>>((ref) {
  // NOTE: We intentionally do NOT chain `.orderBy('createdAt')` after the
  // `where('role')` filter. Filtering on one field and ordering by another
  // requires a Firestore composite index; without it the stream fails with a
  // `failed-precondition` error (the "Failed to load traders" screen).
  // Instead we sort client-side below, which needs no index.
  return FirebaseService.usersRef
      .where('role', isEqualTo: 'trader')
      .snapshots()
      .map((snap) {
    final traders =
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
    traders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return traders;
  });
});

class AdminTradersScreen extends ConsumerStatefulWidget {
  const AdminTradersScreen({super.key});

  @override
  ConsumerState<AdminTradersScreen> createState() =>
      _AdminTradersScreenState();
}

class _AdminTradersScreenState
    extends ConsumerState<AdminTradersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // UPDATE TRADER STATUS
  // ═══════════════════════════════════════
  Future<void> _updateTraderStatus(
    UserModel trader,
    TraderStatus status,
  ) async {
    await FirebaseService.usersRef.doc(trader.uid).update({
      'traderStatus': status.name,
    });

    if (!mounted) return;

    final message = switch (status) {
      TraderStatus.approved => '${trader.name} approved! ✅',
      TraderStatus.blocked => '${trader.name} blocked ❌',
      TraderStatus.pending => '${trader.name} set to pending',
    };

    CustomSnackbar.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final tradersAsync = ref.watch(tradersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          'Trader Management',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96.h),
          child: Column(
            children: [
              // Search
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16.w, 0, 16.w, 10.h),
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search traders...',
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      size: 20.sp,
                      color: AppColors.textHint,
                    ),
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
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
                labelColor: AppColors.adminPrimary,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.adminPrimary,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Blocked'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: tradersAsync.when(
        loading: () => _buildShimmer(),
        error: (err, __) => _buildError(err),
        data: (traders) {
          // Filter by search
          final filtered = _searchQuery.isEmpty
              ? traders
              : traders.where((t) {
                  final q = _searchQuery.toLowerCase();
                  return t.name.toLowerCase().contains(q) ||
                      t.businessName.toLowerCase().contains(q) ||
                      t.phone.contains(q);
                }).toList();

          final pending = filtered
              .where(
                  (t) => t.traderStatus == TraderStatus.pending)
              .toList();
          final approved = filtered
              .where(
                  (t) => t.traderStatus == TraderStatus.approved)
              .toList();
          final blocked = filtered
              .where(
                  (t) => t.traderStatus == TraderStatus.blocked)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTraderList(
                pending,
                showApprove: true,
              ),
              _buildTraderList(
                approved,
                showBlock: true,
              ),
              _buildTraderList(
                blocked,
                showApprove: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTraderList(
    List<UserModel> traders, {
    bool showApprove = false,
    bool showBlock = false,
  }) {
    if (traders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.people,
              size: 48.sp,
              color: AppColors.textHint,
            ),
            Gap(12.h),
            Text(
              'No traders here',
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: traders.length,
      separatorBuilder: (_, __) => Gap(12.h),
      itemBuilder: (context, index) {
        final trader = traders[index];
        return _buildTraderCard(
          trader,
          showApprove: showApprove,
          showBlock: showBlock,
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 60),
              duration: 300.ms,
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildTraderCard(
    UserModel trader, {
    bool showApprove = false,
    bool showBlock = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Row(
            children: [
              // Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    trader.name.isNotEmpty
                        ? trader.name[0].toUpperCase()
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

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trader.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (trader.businessName.isNotEmpty) ...[
                      Gap(2.h),
                      Text(
                        trader.businessName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    Gap(2.h),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 11.sp,
                          color: AppColors.textHint,
                        ),
                        Gap(3.w),
                        Text(
                          trader.city ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                        Gap(8.w),
                        Icon(
                          Iconsax.clock,
                          size: 11.sp,
                          color: AppColors.textHint,
                        ),
                        Gap(3.w),
                        Text(
                          timeago.format(trader.createdAt),
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

              // Call button
              GestureDetector(
                onTap: () async {
                  final uri =
                      Uri.parse('tel:${trader.phone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.approvedLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.call,
                    size: 16.sp,
                    color: AppColors.approved,
                  ),
                ),
              ),
            ],
          ),

          Gap(12.h),

          // Action Buttons Row
          Row(
            children: [
              if (trader.gstNumber != null) ...[
                Icon(
                  Iconsax.document_text,
                  size: 12.sp,
                  color: AppColors.textHint,
                ),
                Gap(4.w),
                Text(
                  'GST: ${trader.gstNumber}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textHint,
                  ),
                ),
                const Spacer(),
              ] else
                const Spacer(),

              // Approve Button
              if (showApprove)
                GestureDetector(
                  onTap: () => _updateTraderStatus(
                    trader,
                    TraderStatus.approved,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.approved,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 14.sp,
                          color: AppColors.white,
                        ),
                        Gap(4.w),
                        Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Block Button
              if (showBlock)
                GestureDetector(
                  onTap: () => _updateTraderStatus(
                    trader,
                    TraderStatus.blocked,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.rejectedLight,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.rejected.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.close_circle,
                          size: 14.sp,
                          color: AppColors.rejected,
                        ),
                        Gap(4.w),
                        Text(
                          'Block',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.rejected,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 48.sp,
              color: AppColors.textHint,
            ),
            Gap(12.h),
            Text(
              'Failed to load traders',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Gap(6.h),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textHint,
              ),
            ),
            Gap(16.h),
            GestureDetector(
              onTap: () => ref.invalidate(tradersStreamProvider),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      separatorBuilder: (_, __) => Gap(12.h),
      itemBuilder: (_, __) => ShimmerLoading(
        width: double.infinity,
        height: 120.h,
        borderRadius: 16.r,
      ),
    );
  }
}
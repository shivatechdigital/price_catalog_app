// lib/features/admin/dashboard/widgets/trader_request_notification.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/user_model.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

// Pending traders count - admin dashboard pe badge ke liye
final pendingTradersCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'trader')
      .where('traderStatus', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);
});

// Pending traders list
final pendingTradersProvider =
    StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'trader')
      .where('traderStatus', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList());
});

class PendingTradersBanner extends ConsumerWidget {
  const PendingTradersBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingTradersCountProvider);
    final count = countAsync.value ?? 0;

    if (count == 0) return const SizedBox();

    return GestureDetector(
      onTap: () => _showPendingTradersSheet(context, ref),
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.traderPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Iconsax.people,
                      size: 20.sp,
                      color: AppColors.white,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: AppColors.rejected,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count New Trader ${count == 1 ? 'Request' : 'Requests'}!',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Tap to review and approve',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: AppColors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingTradersSheet(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingTradersSheet(),
    );
  }
}

// ─── Pending Traders Bottom Sheet ───────────────────────────
class _PendingTradersSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradersAsync = ref.watch(pendingTradersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Gap(12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          Gap(16.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.traderPrimary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.people,
                    size: 18.sp,
                    color: AppColors.traderPrimary,
                  ),
                ),
                Gap(10.w),
                Text(
                  'Pending Trader Requests',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Gap(12.h),
          const Divider(),

          // List
          Expanded(
            child: tradersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load'),
              ),
              data: (traders) {
                if (traders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 48.sp,
                          color: AppColors.approved,
                        ),
                        Gap(12.h),
                        Text(
                          'No pending requests!',
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
                  separatorBuilder: (_, __) => Gap(10.h),
                  itemBuilder: (context, index) {
                    return _PendingTraderCard(
                      trader: traders[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single Pending Trader Card ──────────────────────────────
class _PendingTraderCard extends ConsumerStatefulWidget {
  final UserModel trader;

  const _PendingTraderCard({required this.trader});

  @override
  ConsumerState<_PendingTraderCard> createState() =>
      _PendingTraderCardState();
}

class _PendingTraderCardState
    extends ConsumerState<_PendingTraderCard> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _approve() async {
    setState(() => _isApproving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.trader.uid)
          .update({
        'traderStatus': 'approved',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Notify trader
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.trader.uid)
          .collection('items')
          .add({
        'title': '✅ Account Approved!',
        'message':
            'Your account has been approved. You can now login and use the app.',
        'type': 'accountApproved',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackbar.showSuccess(
          context,
          '✅ ${widget.trader.name} approved successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to approve.');
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isRejecting = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.trader.uid)
          .update({
        'traderStatus': 'blocked',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackbar.showSuccess(
          context,
          '${widget.trader.name} rejected.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to reject.');
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trader = widget.trader;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
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
          // ─── Trader Info ─────────────────────────────
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: AppColors.traderGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    trader.name.isNotEmpty
                        ? trader.name[0].toUpperCase()
                        : 'T',
                    style: TextStyle(
                      fontSize: 18.sp,
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
                  children: [
                    Text(
                      trader.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      trader.businessName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.counterLight,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppColors.counter,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          Gap(10.h),

          // ─── Details ─────────────────────────────────
          Row(
            children: [
              _infoChip(Iconsax.call, trader.phone),
              Gap(8.w),
              if (trader.city != null)
                _infoChip(Iconsax.location, trader.city!),
            ],
          ),

          if (trader.gstNumber != null) ...[
            Gap(4.h),
            _infoChip(
              Iconsax.document_text,
              'GST: ${trader.gstNumber}',
            ),
          ],

          Gap(12.h),

          // ─── Action Buttons ──────────────────────────
          Row(
            children: [
              // Reject
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: OutlinedButton(
                    onPressed: _isApproving || _isRejecting
                        ? null
                        : _reject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.rejected,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isRejecting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.rejected,
                            ),
                          )
                        : Text(
                            '❌ Reject',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.rejected,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              Gap(10.w),

              // Approve
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40.h,
                  child: ElevatedButton(
                    onPressed: _isApproving || _isRejecting
                        ? null
                        : _approve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approved,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: _isApproving
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            '✅ Approve Now',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.textHint),
        Gap(4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
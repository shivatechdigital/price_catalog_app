// lib/features/auth/screens/pending_approval_screen.dart
// COMPLETE REPLACEMENT

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/user_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';

// ─── Stream Provider: Real-time trader status ───────────────
final _traderStatusStreamProvider =
    StreamProvider<TraderStatus?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    final statusStr = data['traderStatus'] as String?;
    if (statusStr == null) return null;
    return TraderStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => TraderStatus.pending,
    );
  });
});

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real-time status listen karo
    ref.listen<AsyncValue<TraderStatus?>>(
      _traderStatusStreamProvider,
      (previous, next) {
        next.whenData((status) async {
          if (status == TraderStatus.approved) {
            // ✅ Admin ne approve kiya!
            // Auth provider ko force reload karo
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
              if (doc.exists) {
                final user = UserModel.fromFirestore(doc);
                ref.read(currentUserProvider.notifier).state = user;

                // AuthStateNotifier ko bhi update karo
                // Ye router redirect trigger karega
                if (context.mounted) {
                  // Force re-check auth state
                  await ref.read(authStateProvider.notifier).loadUserDataPublic(uid);
                }
              }
            }
          } else if (status == TraderStatus.blocked) {
            // ❌ Block ho gaya
            if (context.mounted) {
              _showBlockedDialog(context, ref);
            }
          }
        });
      },
    );

    final statusAsync = ref.watch(_traderStatusStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),

              // ═══════════════════════════════════════
              // STATUS INDICATOR
              // ═══════════════════════════════════════
              statusAsync.when(
                loading: () => _buildPendingUI(),
                error: (_, __) => _buildPendingUI(),
                data: (status) {
                  return switch (status) {
                    TraderStatus.approved => _buildApprovedUI(),
                    TraderStatus.blocked => _buildBlockedUI(),
                    _ => _buildPendingUI(),
                  };
                },
              ),

              const Spacer(),

              // ═══════════════════════════════════════
              // LOGOUT
              // ═══════════════════════════════════════
              TextButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                icon: Icon(
                  Iconsax.logout,
                  size: 18.sp,
                  color: AppColors.rejected,
                ),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.rejected,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              Gap(24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PENDING UI ─────────────────────────────────────
  Widget _buildPendingUI() {
    return Column(
      children: [
        // Animated Clock
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColors.counter.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: AppColors.counter.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.clock,
                size: 44.sp,
                color: AppColors.counter,
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.05, 1.05),
              end: const Offset(1.0, 1.0),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),

        Gap(32.h),

        Text(
          'Approval Pending! ⏳',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

        Gap(12.h),

        Text(
          'Your registration has been submitted.\n'
          'Admin will review and approve your account.',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        Gap(32.h),

        // Steps
        _buildStepItem(
          step: '1',
          title: 'Registration Submitted ✅',
          subtitle: 'Your details have been sent to admin',
          isDone: true,
          delay: 400,
        ),
        Gap(12.h),
        _buildStepItem(
          step: '2',
          title: 'Admin Review...',
          subtitle: 'Admin is verifying your details',
          isDone: false,
          delay: 500,
          isActive: true,
        ),
        Gap(12.h),
        _buildStepItem(
          step: '3',
          title: 'Account Activated',
          subtitle: 'You will be auto-redirected once approved',
          isDone: false,
          delay: 600,
        ),

        Gap(24.h),

        // Live indicator
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 10.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.adminPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.adminPrimary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppColors.approved,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.5, 1.5),
                    duration: 1000.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1.0, 1.0),
                    duration: 1000.ms,
                  ),
              Gap(8.w),
              Text(
                'Listening for approval in real-time...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.adminPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  // ─── APPROVED UI ────────────────────────────────────
  Widget _buildApprovedUI() {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColors.approved.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 64.sp,
            color: AppColors.approved,
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),

        Gap(24.h),

        Text(
          'Account Approved! 🎉',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.approved,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        Gap(12.h),

        Text(
          'Welcome! Redirecting you to dashboard...',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),

        Gap(24.h),

        CircularProgressIndicator(
          color: AppColors.approved,
          strokeWidth: 2.5,
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  // ─── BLOCKED UI ─────────────────────────────────────
  Widget _buildBlockedUI() {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColors.rejected.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.block_rounded,
            size: 64.sp,
            color: AppColors.rejected,
          ),
        ).animate().fadeIn(),

        Gap(24.h),

        Text(
          'Account Blocked ❌',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.rejected,
          ),
        ),

        Gap(12.h),

        Text(
          'Your account has been blocked.\nPlease contact admin for support.',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showBlockedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Account Blocked'),
        content: const Text(
          'Your account has been blocked by admin. '
          'Please contact support for assistance.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rejected,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String subtitle,
    required bool isDone,
    required int delay,
    bool isActive = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.approvedLight
            : isActive
                ? AppColors.counterLight
                : AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDone
              ? AppColors.approved.withOpacity(0.3)
              : isActive
                  ? AppColors.counter.withOpacity(0.3)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.approved
                  : isActive
                      ? AppColors.counter
                      : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 18.sp,
                    )
                  : isActive
                      ? Icon(
                          Iconsax.clock,
                          color: AppColors.white,
                          size: 16.sp,
                        )
                      : Text(
                          step,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
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
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? AppColors.approved
                        : isActive
                            ? AppColors.counter
                            : AppColors.textPrimary,
                  ),
                ),
                Gap(2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0);
  }
}
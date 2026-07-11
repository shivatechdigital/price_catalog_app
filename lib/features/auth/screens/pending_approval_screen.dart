import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),

              // ═══════════════════════════════════════
              // ANIMATION / ILLUSTRATION
              // ═══════════════════════════════════════
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  color: AppColors.counter.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.counter.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.clock,
                      size: 48.sp,
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

              Gap(40.h),

              // ═══════════════════════════════════════
              // TITLE
              // ═══════════════════════════════════════
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

              Gap(36.h),

              // ═══════════════════════════════════════
              // STEPS
              // ═══════════════════════════════════════
              _buildStepItem(
                step: '1',
                title: 'Registration Submitted',
                subtitle: 'Your details have been sent to admin',
                isDone: true,
                delay: 400,
              ),

              Gap(16.h),

              _buildStepItem(
                step: '2',
                title: 'Admin Review',
                subtitle: 'Admin will verify your details',
                isDone: false,
                delay: 500,
              ),

              Gap(16.h),

              _buildStepItem(
                step: '3',
                title: 'Account Activated',
                subtitle: 'You will be notified once approved',
                isDone: false,
                delay: 600,
              ),

              const Spacer(),

              // ═══════════════════════════════════════
              // LOGOUT BUTTON
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

  Widget _buildStepItem({
    required String step,
    required String title,
    required String subtitle,
    required bool isDone,
    required int delay,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.approvedLight
            : AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDone
              ? AppColors.approved.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isDone ? AppColors.approved : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 18.sp,
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? AppColors.approved
                        : AppColors.textPrimary,
                  ),
                ),
                Gap(2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
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
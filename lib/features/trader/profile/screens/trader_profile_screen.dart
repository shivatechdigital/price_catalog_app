import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/requirement_export_service.dart';
import 'package:price_catalog_app/features/auth/screens/legal_information_screen.dart';
import 'package:price_catalog_app/features/trader/reports/screens/trader_reports_screen.dart';
import 'package:price_catalog_app/features/auth/screens/profile_edit_screen.dart';
import 'package:price_catalog_app/features/trader/notifications/screens/trader_notifications_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class TraderProfileScreen extends ConsumerWidget {
  const TraderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final unreadCount = currentUser != null
        ? ref
              .watch(unreadCountProvider(currentUser.uid))
              .maybeWhen(data: (count) => count, orElse: () => 0)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            title: Text(
              'My Profile',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: AppColors.traderGradient,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              currentUser?.name.isNotEmpty == true
                                  ? currentUser!.name[0].toUpperCase()
                                  : 'T',
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.name ?? 'Trader',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              Gap(6.h),
                              Text(
                                currentUser?.businessName.isNotEmpty == true
                                    ? currentUser!.businessName
                                    : 'Trader account',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.white.withOpacity(0.85),
                                ),
                              ),
                              Gap(6.h),
                              Text(
                                currentUser?.email ?? '',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileEditScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Iconsax.edit,
                              size: 18.sp,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Gap(24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      _ProfileActionTile(
                        icon: Iconsax.notification,
                        label: 'Notifications',
                        subtitle: 'View unread alerts and updates',
                        badgeCount: unreadCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TraderNotificationsScreen(),
                          ),
                        ),
                        color: AppColors.traderPrimary,
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.chart_2,
                        label: 'My Reports',
                        subtitle: 'Stats, customers & product insights',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TraderReportsScreen(),
                          ),
                        ),
                        color: const Color(0xFF7C3AED),
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.pen_tool,
                        label: 'Edit Profile',
                        subtitle: 'Update your contact and business info',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        ),
                        color: AppColors.adminPrimary,
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.info_circle,
                        label: 'About App',
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          CustomSnackbar.showInfo(
                            context,
                            'PriceCatalog App v1.0.0',
                          );
                        },
                        color: AppColors.textSecondary,
                      ),
                      Gap(12.h),
                      _ExportRequirementsActionTile(
                        currentUserId: currentUser?.uid ?? '',
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.message_question,
                        label: 'Help & Support',
                        subtitle: 'Contact support if you need help',
                        onTap: () {
                          CustomSnackbar.showInfo(
                            context,
                            'For support, reach out to the app owner.',
                          );
                        },
                        color: AppColors.adminPrimary,
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.shield_tick,
                        label: 'Privacy Policy',
                        subtitle: 'View privacy and data deletion details',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalInformationScreen(
                              title: 'Privacy Policy',
                            ),
                          ),
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Gap(24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Gap(12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Email',
                          value: currentUser?.email ?? '-',
                        ),
                        _DetailRow(
                          label: 'Phone',
                          value: currentUser?.phone ?? '-',
                        ),
                        _DetailRow(
                          label: 'Business',
                          value: currentUser?.businessName.isNotEmpty == true
                              ? currentUser!.businessName
                              : '-',
                        ),
                        _DetailRow(
                          label: 'City',
                          value: currentUser?.city ?? '-',
                        ),
                        _DetailRow(
                          label: 'GST Number',
                          value: currentUser?.gstNumber ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),
                Gap(28.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => _confirmDeleteAccount(context, ref),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.rejectedLight,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.rejected.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.trash,
                            color: AppColors.rejected,
                            size: 20.sp,
                          ),
                          Gap(10.w),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.rejected,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap(12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => ref.read(authStateProvider.notifier).logout(),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.rejectedLight,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.logout,
                            color: AppColors.rejected,
                            size: 20.sp,
                          ),
                          Gap(10.w),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.rejected,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap(40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account profile and uploaded personal files will be permanently deleted. This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rejected),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    final password = passwordController.text;
    passwordController.dispose();
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(authStateProvider.notifier)
        .deleteAccount(password: password);
    if (!context.mounted || result.isSuccess) return;
    CustomSnackbar.showError(context, result.errorMessage!);
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int badgeCount;
  final VoidCallback onTap;
  final Color color;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, size: 22.sp, color: color),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                width: 20.w,
                height: 20.w,
                decoration: const BoxDecoration(
                  color: AppColors.rejected,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: TextStyle(
                      fontSize: 10.sp,
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textHint),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: AppColors.border, height: 1),
      ],
    );
  }
}

// ═══════════════════════════════════════
// EXPORT REQUIREMENTS TILE
// ═══════════════════════════════════════
class _ExportRequirementsActionTile extends ConsumerWidget {
  final String currentUserId;

  const _ExportRequirementsActionTile({required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementsAsync = ref.watch(
      traderRequirementsProvider(currentUserId),
    );

    return requirementsAsync.when(
      loading: () => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.traderPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.traderPrimary,
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
                    'Export All Requirements',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    'Loading your requirements...',
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
      ),
      error: (_, __) => const SizedBox(),
      data: (requirements) {
        return GestureDetector(
          onTap: requirements.isEmpty
              ? null
              : () async {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        'Export Requirements',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        'Export ${requirements.length} requirement(s) as PDF?',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final success =
                                await RequirementExportService.shareRequirementsExport(
                                  requirements,
                                  range: ExportRange.all,
                                  fileNamePrefix: 'My_Requirements',
                                  format: ExportFormat.pdf,
                                );

                            if (context.mounted) {
                              CustomSnackbar.showSuccess(
                                context,
                                success
                                    ? '✅ Requirements exported successfully!'
                                    : '❌ Failed to export. Try again.',
                              );
                            }
                          },
                          child: Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.traderPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: requirements.isEmpty
                  ? null
                  : LinearGradient(
                      colors: [
                        AppColors.traderPrimary.withOpacity(0.1),
                        AppColors.traderPrimary.withOpacity(0.05),
                      ],
                    ),
              color: requirements.isEmpty
                  ? AppColors.border.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: requirements.isEmpty
                    ? AppColors.border
                    : AppColors.traderPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.traderPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Iconsax.export,
                    size: 22.sp,
                    color: requirements.isEmpty
                        ? AppColors.textHint
                        : AppColors.traderPrimary,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export All Requirements',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: requirements.isEmpty
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        requirements.isEmpty
                            ? 'No requirements to export'
                            : 'Download ${requirements.length} requirement(s) as PDF',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (requirements.isNotEmpty)
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16.sp,
                    color: AppColors.traderPrimary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

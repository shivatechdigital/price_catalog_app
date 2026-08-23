import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/requirement_export_service.dart';
import 'package:price_catalog_app/features/admin/reports/screens/admin_reports_screen.dart';
import 'package:price_catalog_app/features/auth/screens/profile_edit_screen.dart';
import 'package:price_catalog_app/features/auth/screens/legal_information_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

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
            surfaceTintColor: Colors.transparent,
            elevation: 0,
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
                // ═══════════════════════════════════════
                // PROFILE HEADER WITH GRADIENT
                // ═══════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.adminPrimary,
                          AppColors.adminPrimary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.adminPrimary.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              currentUser?.name.isNotEmpty == true
                                  ? currentUser!.name[0].toUpperCase()
                                  : 'A',
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentUser?.name ?? 'Admin',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
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
                              border: Border.all(
                                color: AppColors.white.withOpacity(0.2),
                              ),
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

                // ═══════════════════════════════════════
                // ACTION TILES
                // ═══════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      _ProfileActionTile(
                        icon: Iconsax.notification,
                        label: 'Notifications',
                        subtitle: 'View system alerts and updates',
                        badgeCount: unreadCount,
                        onTap: () {
                          // Navigate to notifications
                        },
                        color: AppColors.adminPrimary,
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.chart_2,
                        label: 'Reports & Analytics',
                        subtitle: 'Sales, products & trader insights',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminReportsScreen(),
                          ),
                        ),
                        color: const Color(0xFF7C3AED),
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
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.pen_tool,
                        label: 'Edit Profile',
                        subtitle: 'Update your contact information',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        ),
                        color: AppColors.traderPrimary,
                      ),
                      Gap(12.h),
                      _AdminExportRequirementsActionTile(),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.info_circle,
                        label: 'About App',
                        subtitle: 'Version 1.0.0 - Admin Panel',
                        onTap: () {
                          CustomSnackbar.showInfo(
                            context,
                            'PriceCatalog Admin Panel v1.0.0',
                          );
                        },
                        color: AppColors.textSecondary,
                      ),
                      Gap(12.h),
                      _ProfileActionTile(
                        icon: Iconsax.message_question,
                        label: 'Help & Support',
                        subtitle: 'Get help with admin features',
                        onTap: () {
                          CustomSnackbar.showInfo(
                            context,
                            'For support, contact the development team.',
                          );
                        },
                        color: AppColors.adminPrimary,
                      ),
                    ],
                  ),
                ),

                Gap(24.h),

                // ═══════════════════════════════════════
                // ADMIN DETAILS
                // ═══════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Admin Details',
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
                        _DetailRow(label: 'Role', value: 'Administrator'),
                        _DetailRow(
                          label: 'Status',
                          value: 'Active',
                          isLast: true,
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

                // ═══════════════════════════════════════
                // LOGOUT BUTTON
                // ═══════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => ref.read(authStateProvider.notifier).logout(),
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
              'Your admin account profile and uploaded personal files will be permanently deleted. This action cannot be undone.',
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

// ═══════════════════════════════════════
// ACTION TILE WIDGET
// ═══════════════════════════════════════
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
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: AppColors.rejected,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Iconsax.arrow_right_3,
                size: 16.sp,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// DETAIL ROW
// ═══════════════════════════════════════
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

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
        if (!isLast) Divider(color: AppColors.border, height: 1),
      ],
    );
  }
}

// ═══════════════════════════════════════
// ADMIN EXPORT REQUIREMENTS TILE
// ═══════════════════════════════════════
class _AdminExportRequirementsActionTile extends ConsumerWidget {
  const _AdminExportRequirementsActionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementsAsync = ref.watch(allRequirementsProvider);

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
                color: AppColors.adminPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.adminPrimary,
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
                    'Loading data...',
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
                        'Export All Requirements',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        'Export all ${requirements.length} requirement(s) as PDF?\n\nThis includes all statuses (pending, approved, rejected, counter-offer).',
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
                                  fileNamePrefix: 'All_Requirements_Export',
                                  format: ExportFormat.pdf,
                                );

                            if (context.mounted) {
                              CustomSnackbar.showSuccess(
                                context,
                                success
                                    ? '✅ ${requirements.length} requirement(s) exported successfully!'
                                    : '❌ Failed to export. Try again.',
                              );
                            }
                          },
                          child: Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adminPrimary,
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
                        AppColors.adminPrimary.withOpacity(0.1),
                        AppColors.adminPrimary.withOpacity(0.05),
                      ],
                    ),
              color: requirements.isEmpty
                  ? AppColors.border.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: requirements.isEmpty
                    ? AppColors.border
                    : AppColors.adminPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Iconsax.export,
                    size: 22.sp,
                    color: requirements.isEmpty
                        ? AppColors.textHint
                        : AppColors.adminPrimary,
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
                            ? 'No data to export'
                            : 'Download ${requirements.length} requirement(s) with all statuses',
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
                    color: AppColors.adminPrimary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

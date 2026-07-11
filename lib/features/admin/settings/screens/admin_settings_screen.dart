import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/features/admin/traders/screens/admin_traders_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Gap(16.h),

                // Profile Card
                _buildProfileCard(currentUser),

                Gap(20.h),

                // Settings Groups
                _buildSettingsGroup(
                  title: 'Business',
                  items: [
                    _SettingsItem(
                      icon: Iconsax.people,
                      label: 'Trader Management',
                      subtitle: 'Approve & manage traders',
                      color: AppColors.adminPrimary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdminTradersScreen(),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Iconsax.building,
                      label: 'Company Profile',
                      subtitle: 'Update company information',
                      color: AppColors.traderPrimary,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Iconsax.percentage_square,
                      label: 'Pricing Rules',
                      subtitle: 'Set pricing policies',
                      color: AppColors.approved,
                      onTap: () {},
                    ),
                  ],
                ),

                Gap(16.h),

                _buildSettingsGroup(
                  title: 'App',
                  items: [
                    _SettingsItem(
                      icon: Iconsax.notification,
                      label: 'Notifications',
                      subtitle: 'Manage push notifications',
                      color: AppColors.counter,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Iconsax.security,
                      label: 'Security',
                      subtitle: 'Password & data security',
                      color: AppColors.adminPrimary,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Iconsax.export,
                      label: 'Export Data',
                      subtitle: 'Download all data as Excel/PDF',
                      color: AppColors.approved,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Iconsax.refresh,
                      label: 'Backup & Restore',
                      subtitle: 'Cloud backup settings',
                      color: AppColors.adminPrimary,
                      onTap: () {},
                    ),
                  ],
                ),

                Gap(16.h),

                _buildSettingsGroup(
                  title: 'Support',
                  items: [
                    _SettingsItem(
                      icon: Iconsax.info_circle,
                      label: 'About App',
                      subtitle: 'Version 1.0.0',
                      color: AppColors.textSecondary,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Iconsax.message_question,
                      label: 'Help & Support',
                      subtitle: 'Contact support team',
                      color: AppColors.adminPrimary,
                      onTap: () {},
                    ),
                  ],
                ),

                Gap(16.h),

                // Logout
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => _showLogoutDialog(context, ref),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.rejectedLight,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.rejected.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.logout,
                            size: 20.sp,
                            color: AppColors.rejected,
                          ),
                          Gap(10.w),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rejected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap(60.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PROFILE CARD
  // ═══════════════════════════════════════
  Widget _buildProfileCard(currentUser) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.adminGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withOpacity(0.4),
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name ?? 'Admin',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Gap(3.h),
                Text(
                  currentUser?.businessName ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                Gap(3.h),
                Text(
                  currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),

          // Edit
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Iconsax.edit,
              size: 18.sp,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.95, 0.95),
          curve: Curves.elasticOut,
        );
  }

  // ═══════════════════════════════════════
  // SETTINGS GROUP
  // ═══════════════════════════════════════
  Widget _buildSettingsGroup({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  GestureDetector(
                    onTap: item.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color:
                                  item.color.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              item.icon,
                              size: 18.sp,
                              color: item.color,
                            ),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.textHint,
                                    ),
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
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 66.w,
                      color: AppColors.divider,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // LOGOUT DIALOG
  // ═══════════════════════════════════════
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Logout?',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout from your admin account?',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rejected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
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
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });
}
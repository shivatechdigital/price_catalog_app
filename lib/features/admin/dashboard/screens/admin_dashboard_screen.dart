import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/features/admin/categories/screens/admin_categories_screen.dart';
import 'package:price_catalog_app/features/admin/dashboard/screens/admin_home_screen.dart';
import 'package:price_catalog_app/features/admin/products/screens/admin_products_screen.dart';
import 'package:price_catalog_app/features/admin/requirements/screens/admin_requirements_screen.dart';
import 'package:price_catalog_app/features/admin/settings/screens/admin_settings_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';

// ═══════════════════════════════════════
// BOTTOM NAV INDEX PROVIDER
// ═══════════════════════════════════════
final adminNavIndexProvider = StateProvider<int>((ref) => 0);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(adminNavIndexProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Unread notifications count
    final unreadCount = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid))
        : const AsyncValue.data(0);

    final screens = const [
      AdminHomeScreen(),
      AdminProductsScreen(),
      AdminRequirementsScreen(),
      AdminSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(
        context,
        ref,
        currentIndex,
        unreadCount.asData?.value ?? 0,
      ),
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════
  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    int unreadCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 8.h,
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: currentIndex == 0,
                  onTap: () => ref
                      .read(adminNavIndexProvider.notifier)
                      .state = 0,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  isActive: currentIndex == 1,
                  onTap: () => ref
                      .read(adminNavIndexProvider.notifier)
                      .state = 1,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Requirements',
                  isActive: currentIndex == 2,
                  badgeCount: unreadCount,
                  onTap: () => ref
                      .read(adminNavIndexProvider.notifier)
                      .state = 2,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Iconsax.user,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () => ref
                      .read(adminNavIndexProvider.notifier)
                      .state = 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// NAV ITEM WIDGET
// ═══════════════════════════════════════
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12.w : 10.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.adminPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: isActive
                      ? AppColors.adminPrimary
                      : AppColors.textHint,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: const BoxDecoration(
                        color: AppColors.rejected,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isActive
                    ? AppColors.adminPrimary
                    : AppColors.textHint,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
} 
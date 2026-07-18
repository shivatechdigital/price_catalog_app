import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/features/trader/catalog/screens/trader_catalog_screen.dart';
import 'package:price_catalog_app/features/trader/dashboard/screens/trader_home_screen.dart';
import 'package:price_catalog_app/features/trader/notifications/screens/trader_notifications_screen.dart';
import 'package:price_catalog_app/features/trader/profile/screens/trader_profile_screen.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/trader_requirements_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';

// ═══════════════════════════════════════
// TRADER NAV INDEX PROVIDER
// ═══════════════════════════════════════
final traderNavIndexProvider = StateProvider<int>((ref) => 0);

class TraderDashboardScreen extends ConsumerWidget {
  const TraderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(traderNavIndexProvider);
    final currentUser = ref.watch(currentUserProvider);

    final unreadCount = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid))
        : const AsyncValue.data(0);

    final screens = const [
      TraderHomeScreen(),
      TraderCatalogScreen(),
      TraderRequirementsScreen(),
      TraderProfileScreen(),
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
        unreadCount.when(
          data: (count) => count,
          loading: () => 0,
          error: (_, __) => 0,
        ),
      ),
    );
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TraderNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 0,
                primaryColor: AppColors.traderPrimary,
              ),
              _TraderNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Catalog',
                isActive: currentIndex == 1,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 1,
                primaryColor: AppColors.traderPrimary,
              ),
              _TraderNavItem(
                icon: Icons.assignment_rounded,
                label: 'My Deals',
                isActive: currentIndex == 2,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 2,
                primaryColor: AppColors.traderPrimary,
              ),
              _TraderNavItem(
                icon: Iconsax.user,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => ref
                    .read(traderNavIndexProvider.notifier)
                    .state = 3,
                primaryColor: AppColors.traderPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TRADER NAV ITEM
// ═══════════════════════════════════════
class _TraderNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;
  final Color primaryColor;

  const _TraderNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.primaryColor,
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
              ? primaryColor.withOpacity(0.12)
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
                      ? primaryColor
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
                    ? primaryColor
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
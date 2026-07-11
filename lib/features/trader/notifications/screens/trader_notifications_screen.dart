import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class TraderNotificationsScreen extends ConsumerWidget {
  const TraderNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final notificationsAsync = currentUser != null
        ? ref.watch(notificationsStreamProvider(currentUser.uid))
        : const AsyncValue.data(<NotificationModel>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (currentUser != null) {
                ref
                    .read(notificationRepositoryProvider)
                    .markAllAsRead(currentUser.uid);
              }
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.traderPrimary,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const Center(
          child: Text('Failed to load notifications'),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.notification,
                    size: 52.sp,
                    color: AppColors.textHint,
                  ),
                  Gap(16.h),
                  Text(
                    'No notifications yet',
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
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Gap(8.h),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return GestureDetector(
                onTap: () {
                  if (currentUser != null && !notif.read) {
                    ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(currentUser.uid, notif.id);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: notif.read
                        ? AppColors.white
                        : AppColors.traderPrimary
                            .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: notif.read
                          ? AppColors.border
                          : AppColors.traderPrimary
                              .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: _getNotifColor(notif.type)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotifIcon(notif.type),
                          size: 22.sp,
                          color: _getNotifColor(notif.type),
                        ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: notif.read
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Gap(3.h),
                            Text(
                              notif.message,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            Gap(4.h),
                            Text(
                              timeago.format(notif.createdAt),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notif.read)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: AppColors.traderPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getNotifColor(NotificationType type) {
    return switch (type) {
      NotificationType.requirementApproved => AppColors.approved,
      NotificationType.requirementRejected => AppColors.rejected,
      NotificationType.counterOffer => AppColors.counter,
      NotificationType.priceUpdated => AppColors.adminPrimary,
      _ => AppColors.traderPrimary,
    };
  }

  IconData _getNotifIcon(NotificationType type) {
    return switch (type) {
      NotificationType.requirementApproved =>
        Icons.check_circle_rounded,
      NotificationType.requirementRejected =>
        Icons.cancel_rounded,
      NotificationType.counterOffer =>
        Icons.compare_arrows_rounded,
      NotificationType.priceUpdated => Icons.trending_up_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/notification_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/notification_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (currentUser != null) {
                ref
                    .read(notificationRepositoryProvider)
                    .markAllAsRead(currentUser.uid);
                CustomSnackbar.showSuccess(context, 'All marked as read');
              }
            },
            icon: Icon(
              Iconsax.tick_circle,
              size: 18.sp,
              color: AppColors.adminPrimary,
            ),
            label: Text(
              'Mark all',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.adminPrimary,
          ),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 48.sp,
                color: AppColors.rejected,
              ),
              Gap(16.h),
              Text(
                'Failed to load notifications',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.notification,
                      size: 40.sp,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  Gap(20.h),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    'Your notifications will appear here',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _AdminNotificationCard(
                notification: notif,
                index: index,
                onTap: () => _handleNotificationTap(
                  context,
                  ref,
                  notif,
                  currentUser?.uid,
                ),
                onDelete: () {
                  if (currentUser != null) {
                    ref
                        .read(notificationRepositoryProvider)
                        .deleteNotification(currentUser.uid, notif.id);
                    CustomSnackbar.showSuccess(context, 'Notification deleted');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
    String? userId,
  ) {
    // Mark as read
    if (userId != null && !notif.read) {
      ref
          .read(notificationRepositoryProvider)
          .markAsRead(userId, notif.id);
    }

    // Navigate based on notification type
    if (notif.referenceId != null) {
      switch (notif.type) {
        case NotificationType.newRequirement:
        case NotificationType.requirementApproved:
        case NotificationType.requirementRejected:
        case NotificationType.counterOffer:
          // Navigate to requirement detail - admin view
          context.push('/admin/requirements/${notif.referenceId}');
          break;
        case NotificationType.newTrader:
          // Navigate to traders screen
          context.push('/admin/traders');
          break;
        case NotificationType.newProduct:
          // Navigate to products screen
          context.push('/admin/products');
          break;
        default:
          break;
      }
    }
  }

  Color _getNotifColor(NotificationType type) {
    return switch (type) {
      NotificationType.newRequirement => AppColors.pending,
      NotificationType.requirementApproved => AppColors.approved,
      NotificationType.requirementRejected => AppColors.rejected,
      NotificationType.counterOffer => AppColors.counter,
      NotificationType.newTrader => AppColors.adminPrimary,
      NotificationType.newProduct => AppColors.approved,
      NotificationType.priceUpdated => AppColors.counter,
    };
  }

  IconData _getNotifIcon(NotificationType type) {
    return switch (type) {
      NotificationType.newRequirement => Iconsax.notification_bing,
      NotificationType.requirementApproved => Icons.check_circle_rounded,
      NotificationType.requirementRejected => Icons.cancel_rounded,
      NotificationType.counterOffer => Icons.compare_arrows_rounded,
      NotificationType.newTrader => Iconsax.user_add,
      NotificationType.newProduct => Iconsax.box_add,
      NotificationType.priceUpdated => Icons.trending_up_rounded,
    };
  }
}

// ═══════════════════════════════════════
// ADMIN NOTIFICATION CARD WIDGET
// ═══════════════════════════════════════
class _AdminNotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AdminNotificationCard({
    required this.notification,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getNotifColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.rejected,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(
          Iconsax.trash,
          color: AppColors.white,
          size: 20.sp,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: notification.read
                ? AppColors.white
                : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: notification.read
                  ? AppColors.border
                  : color.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: notification.read
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container with Gradient
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getNotifIcon(notification.type),
                  size: 24.sp,
                  color: color,
                ),
              ),
              Gap(12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: notification.read
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 6.w,
                            height: 6.w,
                            margin: EdgeInsets.only(left: 8.w),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Gap(6.h),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(8.h),
                    Text(
                      timeago.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Icon
              Gap(8.w),
              Icon(
                Iconsax.arrow_right_3,
                size: 16.sp,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .slideX(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }

  Color _getNotifColor(NotificationType type) {
    return switch (type) {
      NotificationType.newRequirement => AppColors.pending,
      NotificationType.requirementApproved => AppColors.approved,
      NotificationType.requirementRejected => AppColors.rejected,
      NotificationType.counterOffer => AppColors.counter,
      NotificationType.newTrader => AppColors.adminPrimary,
      NotificationType.newProduct => AppColors.approved,
      NotificationType.priceUpdated => AppColors.counter,
    };
  }

  IconData _getNotifIcon(NotificationType type) {
    return switch (type) {
      NotificationType.newRequirement => Iconsax.notification_bing,
      NotificationType.requirementApproved => Icons.check_circle_rounded,
      NotificationType.requirementRejected => Icons.cancel_rounded,
      NotificationType.counterOffer => Icons.compare_arrows_rounded,
      NotificationType.newTrader => Iconsax.user_add,
      NotificationType.newProduct => Iconsax.box_add,
      NotificationType.priceUpdated => Icons.trending_up_rounded,
    };
  }
}

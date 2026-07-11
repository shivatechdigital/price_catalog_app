import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/order_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/providers/order_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class TraderOrderDetailScreen extends ConsumerWidget {
  final OrderModel order;

  const TraderOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real-time updates
    final orderStream = ref
        .watch(orderRepositoryProvider)
        .watchTraderOrders(traderId: order.traderId)
        .map((orders) => orders.firstWhere(
              (o) => o.id == order.id,
              orElse: () => order,
            ));

    return StreamBuilder<OrderModel>(
      stream: orderStream,
      initialData: order,
      builder: (context, snapshot) {
        final liveOrder = snapshot.data ?? order;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, liveOrder),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Status Summary
                _buildStatusSummary(liveOrder),
                Gap(12.h),

                // Counter Offer Banner
                if (liveOrder.counterCount > 0)
                  _buildCounterBanner(liveOrder),

                if (liveOrder.counterCount > 0) Gap(12.h),

                // Items
                _buildItemsList(context, ref, liveOrder),
                Gap(12.h),

                // Customer
                _buildCustomerCard(liveOrder),
                Gap(12.h),

                // Payment
                _buildPaymentCard(liveOrder),

                if (liveOrder.traderNote != null) ...[
                  Gap(12.h),
                  _buildNoteCard(liveOrder),
                ],

                Gap(60.h),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, OrderModel order) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16.sp,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            'Order Detail',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '#${order.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Iconsax.shop,
                size: 16.sp,
                color: AppColors.traderPrimary,
              ),
              Gap(8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${order.customerBusinessName} • ${order.customerCity}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.orderStatus)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _statusColor(order.orderStatus)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _statusColor(order.orderStatus),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          Gap(14.h),

          // Progress Bar
          Row(
            children: [
              if (order.approvedCount > 0)
                Expanded(
                  flex: order.approvedCount,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: AppColors.approved,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(3.r),
                        bottomLeft: Radius.circular(3.r),
                      ),
                    ),
                  ),
                ),
              if (order.counterCount > 0)
                Expanded(
                  flex: order.counterCount,
                  child: Container(
                    height: 6.h,
                    color: AppColors.counter,
                  ),
                ),
              if (order.rejectedCount > 0)
                Expanded(
                  flex: order.rejectedCount,
                  child: Container(
                    height: 6.h,
                    color: AppColors.rejected,
                  ),
                ),
              if (order.pendingCount > 0)
                Expanded(
                  flex: order.pendingCount,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(3.r),
                        bottomRight: Radius.circular(3.r),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Gap(10.h),

          // Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniCount(
                '${order.approvedCount}',
                'Approved',
                AppColors.approved,
              ),
              _miniCount(
                '${order.counterCount}',
                'Counter',
                AppColors.counter,
              ),
              _miniCount(
                '${order.rejectedCount}',
                'Rejected',
                AppColors.rejected,
              ),
              _miniCount(
                '${order.pendingCount}',
                'Pending',
                AppColors.textSecondary,
              ),
            ],
          ),

          Gap(12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${order.totalOrderValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                timeago.format(order.submittedAt),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildCounterBanner(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.counterLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.counter.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            size: 20.sp,
            color: AppColors.counter,
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.counterCount} Counter ${order.counterCount == 1 ? 'Offer' : 'Offers'} Received!',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.counter,
                  ),
                ),
                Text(
                  'Scroll down to respond to each item',
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
    ).animate().fadeIn(delay: 100.ms).scale(
          begin: const Offset(0.95, 0.95),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildItemsList(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Text(
              '${order.totalItems} Products',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            child: const Divider(height: 1),
          ),

          // Items
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return _TraderItemCard(
              item: item,
              index: index,
              isLast: index == order.items.length - 1,
              onAcceptCounter: item.isCounterOffer
                  ? () => _acceptCounter(
                        context,
                        ref,
                        order.id,
                        item,
                      )
                  : null,
              onRejectCounter: item.isCounterOffer
                  ? () => _rejectCounter(
                        context,
                        ref,
                        order.id,
                        item,
                      )
                  : null,
            ).animate().fadeIn(
                  delay: Duration(milliseconds: index * 80),
                );
          }),
        ],
      ),
    );
  }

  Future<void> _acceptCounter(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    OrderItemModel item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Accept Counter Offer?'),
        content: Text(
          'Accept ₹${item.counterPrice!.toStringAsFixed(0)} for ${item.productName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.approved,
              elevation: 0,
            ),
            child: const Text(
              'Accept ✅',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(orderRepositoryProvider)
        .acceptItemCounterOffer(
          orderId: orderId,
          itemId: item.itemId,
        );

    if (context.mounted) {
      CustomSnackbar.showSuccess(
        context,
        '✅ Counter accepted for ${item.productName}!',
      );
    }
  }

  Future<void> _rejectCounter(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    OrderItemModel item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Reject Counter Offer?'),
        content: Text(
          'Reject counter for ${item.productName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rejected,
              elevation: 0,
            ),
            child: const Text(
              'Reject ❌',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(orderRepositoryProvider)
        .rejectItemCounterOffer(
          orderId: orderId,
          itemId: item.itemId,
        );

    if (context.mounted) {
      CustomSnackbar.showSuccess(
        context,
        'Counter rejected for ${item.productName}.',
      );
    }
  }

  Widget _buildCustomerCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(10.h),
          _row('Name', order.customerName),
          Gap(6.h),
          _row('Business', order.customerBusinessName),
          Gap(6.h),
          _row('Phone', '+91 ${order.customerPhone}'),
          Gap(6.h),
          _row('City', order.customerCity),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment & Delivery',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(10.h),
          _row('Payment', _paymentLabel(order.paymentType)),
          if (order.deliveryDate != null) ...[
            Gap(6.h),
            _row(
              'Delivery',
              '${order.deliveryDate!.day}/${order.deliveryDate!.month}/${order.deliveryDate!.year}',
            ),
          ],
          if (order.deliveryLocation != null) ...[
            Gap(6.h),
            _row('Location', order.deliveryLocation!),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.traderPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.traderPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.note_text,
            size: 16.sp,
            color: AppColors.traderPrimary,
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              order.traderNote!,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  Widget _miniCount(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => AppColors.pending,
      OrderStatus.approved => AppColors.approved,
      OrderStatus.rejected => AppColors.rejected,
      OrderStatus.partial => AppColors.counter,
      OrderStatus.counterOffer => AppColors.counter,
    };
  }

  String _paymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => '💵 Full Cash',
      PaymentType.partialPayment => '💳 Partial',
      PaymentType.credit => '📋 Credit',
    };
  }
}

// ═══════════════════════════════════════
// TRADER ITEM CARD (Per item in trader view)
// ═══════════════════════════════════════
class _TraderItemCard extends StatelessWidget {
  final OrderItemModel item;
  final int index;
  final bool isLast;
  final VoidCallback? onAcceptCounter;
  final VoidCallback? onRejectCounter;

  const _TraderItemCard({
    required this.item,
    required this.index,
    required this.isLast,
    this.onAcceptCounter,
    this.onRejectCounter,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusLabel) =
        switch (item.status) {
      OrderItemStatus.pending => (
          AppColors.pending,
          AppColors.pendingLight,
          'Pending ⏳',
        ),
      OrderItemStatus.approved => (
          AppColors.approved,
          AppColors.approvedLight,
          'Approved ✅',
        ),
      OrderItemStatus.rejected => (
          AppColors.rejected,
          AppColors.rejectedLight,
          'Rejected ❌',
        ),
      OrderItemStatus.counterOffer => (
          AppColors.counter,
          AppColors.counterLight,
          'Counter Offer 🔄',
        ),
    };

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              // ─── Header Row ──────────────────────────────
              Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  if (item.productImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        item.productImage!,
                        width: 36.w,
                        height: 36.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      ),
                    )
                  else
                    _placeholder(),
                  Gap(10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.quantity.toStringAsFixed(0)} ${item.unit} • ₹${item.customerDemandedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
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
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Counter Offer Section ───────────────────
              if (item.isCounterOffer) ...[
                Gap(10.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.counterLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.counter.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _priceCol(
                            'You Asked',
                            '₹${item.customerDemandedPrice.toStringAsFixed(0)}',
                            AppColors.textSecondary,
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16.sp,
                            color: AppColors.counter,
                          ),
                          _priceCol(
                            'Admin Counter',
                            '₹${item.counterPrice!.toStringAsFixed(0)}',
                            AppColors.counter,
                            isBold: true,
                          ),
                          _priceCol(
                            'Difference',
                            '${item.counterPrice! > item.customerDemandedPrice ? '+' : ''}₹${(item.counterPrice! - item.customerDemandedPrice).toStringAsFixed(0)}',
                            item.counterPrice! >
                                    item.customerDemandedPrice
                                ? AppColors.rejected
                                : AppColors.approved,
                          ),
                        ],
                      ),
                      if (item.adminNote != null) ...[
                        Gap(8.h),
                        Text(
                          'Admin: ${item.adminNote}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.counter,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      Gap(10.h),
                      // Accept/Reject Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38.h,
                              child: ElevatedButton(
                                onPressed: onAcceptCounter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.approved,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            9.r),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '✅ Accept',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gap(8.w),
                          Expanded(
                            child: SizedBox(
                              height: 38.h,
                              child: OutlinedButton(
                                onPressed: onRejectCounter,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.rejected,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            9.r),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Rejection reason
              if (item.isRejected &&
                  item.rejectionReason != null) ...[
                Gap(8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.rejectedLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Reason: ${item.rejectionReason}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.rejected,
                    ),
                  ),
                ),
              ],

              // Final price (approved)
              if (item.isApproved && item.finalPrice != null) ...[
                Gap(8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.approvedLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14.sp,
                        color: AppColors.approved,
                      ),
                      Gap(6.w),
                      Text(
                        'Final Price: ₹${item.finalPrice!.toStringAsFixed(0)}/${item.unit}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.approved,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: AppColors.divider,
            indent: 14.w,
            endIndent: 14.w,
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Iconsax.box, size: 18.sp, color: AppColors.textHint),
    );
  }

  Widget _priceCol(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppColors.textHint),
        ),
        Gap(3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight:
                isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
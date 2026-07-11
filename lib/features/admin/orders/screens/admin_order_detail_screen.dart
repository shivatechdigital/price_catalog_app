import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  // Track which item action is loading
  final Map<String, bool> _loadingItems = {};

  // ═══════════════════════════════════════
  // APPROVE SINGLE ITEM
  // ═══════════════════════════════════════
  Future<void> _approveItem(OrderItemModel item) async {
    final note = await _showItemActionDialog(
      title: 'Approve Item',
      subtitle: item.productName,
      color: AppColors.approved,
      icon: Icons.check_circle_rounded,
      showPriceField: true,
      defaultPrice: item.customerDemandedPrice,
    );

    if (note == null) return; // Cancelled

    setState(() => _loadingItems[item.itemId] = true);

    await ref.read(orderRepositoryProvider).updateItemStatus(
          orderId: widget.order.id,
          itemId: item.itemId,
          newStatus: OrderItemStatus.approved,
          finalPrice: note['price'],
          adminNote: note['note'],
        );

    if (mounted) {
      setState(() => _loadingItems[item.itemId] = false);
      CustomSnackbar.showSuccess(
        context,
        '✅ ${item.productName} approved!',
      );
    }
  }

  // ═══════════════════════════════════════
  // COUNTER OFFER SINGLE ITEM
  // ═══════════════════════════════════════
  Future<void> _counterItem(OrderItemModel item) async {
    final result = await _showCounterDialog(item);
    if (result == null) return;

    setState(() => _loadingItems[item.itemId] = true);

    await ref.read(orderRepositoryProvider).updateItemStatus(
          orderId: widget.order.id,
          itemId: item.itemId,
          newStatus: OrderItemStatus.counterOffer,
          counterPrice: result['price'],
          adminNote: result['note'],
        );

    if (mounted) {
      setState(() => _loadingItems[item.itemId] = false);
      CustomSnackbar.showSuccess(
        context,
        '🔄 Counter offer sent for ${item.productName}!',
      );
    }
  }

  // ═══════════════════════════════════════
  // REJECT SINGLE ITEM
  // ═══════════════════════════════════════
  Future<void> _rejectItem(OrderItemModel item) async {
    final result = await _showRejectDialog(item);
    if (result == null) return;

    setState(() => _loadingItems[item.itemId] = true);

    await ref.read(orderRepositoryProvider).updateItemStatus(
          orderId: widget.order.id,
          itemId: item.itemId,
          newStatus: OrderItemStatus.rejected,
          rejectionReason: result['reason'],
          adminNote: result['note'],
        );

    if (mounted) {
      setState(() => _loadingItems[item.itemId] = false);
      CustomSnackbar.showSuccess(
        context,
        '❌ ${item.productName} rejected.',
      );
    }
  }

  // ═══════════════════════════════════════
  // APPROVE ALL PENDING
  // ═══════════════════════════════════════
  Future<void> _approveAllPending() async {
    final confirm = await _showConfirmDialog(
      'Approve All Pending Items?',
      'This will approve ${widget.order.pendingCount} pending items.',
      AppColors.approved,
    );

    if (confirm != true) return;

    await ref.read(orderRepositoryProvider).approveAllPending(
          orderId: widget.order.id,
          adminNote: 'Bulk approved',
        );

    if (mounted) {
      CustomSnackbar.showSuccess(
        context,
        '✅ All pending items approved!',
      );
    }
  }

  // ═══════════════════════════════════════
  // REJECT ALL PENDING
  // ═══════════════════════════════════════
  Future<void> _rejectAllPending() async {
    final confirm = await _showConfirmDialog(
      'Reject All Pending Items?',
      'This will reject ${widget.order.pendingCount} pending items.',
      AppColors.rejected,
    );

    if (confirm != true) return;

    await ref.read(orderRepositoryProvider).rejectAllPending(
          orderId: widget.order.id,
          rejectionReason: 'Bulk rejected by admin',
        );

    if (mounted) {
      CustomSnackbar.showSuccess(
        context,
        '❌ All pending items rejected.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time order updates
    final orderStream = ref
        .watch(orderRepositoryProvider)
        .watchAllOrders()
        .map((orders) => orders.firstWhere(
              (o) => o.id == widget.order.id,
              orElse: () => widget.order,
            ));

    return StreamBuilder<OrderModel>(
      stream: orderStream,
      initialData: widget.order,
      builder: (context, snapshot) {
        final order = snapshot.data ?? widget.order;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── APP BAR ──────────────────────────────────
              _buildAppBar(order),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Gap(16.h),

                    // Order Status Card
                    _buildOrderStatusCard(order),
                    Gap(12.h),

                    // Bulk Actions (only if pending items exist)
                    if (order.pendingCount > 0)
                      _buildBulkActions(order),

                    Gap(12.h),

                    // Items List - THE MAIN SECTION
                    _buildItemsList(order),

                    Gap(12.h),

                    // Customer Details
                    _buildCustomerCard(order),
                    Gap(12.h),

                    // Payment Details
                    _buildPaymentCard(order),

                    if (order.traderNote != null) ...[
                      Gap(12.h),
                      _buildNoteCard(order),
                    ],

                    Gap(60.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════
  Widget _buildAppBar(OrderModel order) {
    final statusColor = switch (order.orderStatus) {
      OrderStatus.pending => AppColors.pending,
      OrderStatus.approved => AppColors.approved,
      OrderStatus.rejected => AppColors.rejected,
      OrderStatus.partial => AppColors.counter,
      OrderStatus.counterOffer => AppColors.counter,
    };

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
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
      actions: [
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: order.id));
            CustomSnackbar.showSuccess(
              context,
              'Order ID copied!',
            );
          },
          child: Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              order.statusLabel,
              style: TextStyle(
                fontSize: 11.sp,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // ORDER STATUS CARD
  // ═══════════════════════════════════════
  Widget _buildOrderStatusCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Trader Info
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    order.traderName.isNotEmpty
                        ? order.traderName[0].toUpperCase()
                        : 'T',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
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
                      order.traderName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      order.traderBusinessName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(
                    'tel:${order.traderPhone}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: AppColors.approvedLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.call,
                    size: 18.sp,
                    color: AppColors.approved,
                  ),
                ),
              ),
            ],
          ),

          Gap(14.h),

          // Progress Summary
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // Progress bar
                Row(
                  children: [
                    if (order.approvedCount > 0)
                      Expanded(
                        flex: order.approvedCount,
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.approved,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4.r),
                              bottomLeft: Radius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    if (order.counterCount > 0)
                      Expanded(
                        flex: order.counterCount,
                        child: Container(
                          height: 8.h,
                          color: AppColors.counter,
                        ),
                      ),
                    if (order.rejectedCount > 0)
                      Expanded(
                        flex: order.rejectedCount,
                        child: Container(
                          height: 8.h,
                          color: AppColors.rejected,
                        ),
                      ),
                    if (order.pendingCount > 0)
                      Expanded(
                        flex: order.pendingCount,
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4.r),
                              bottomRight: Radius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                Gap(10.h),

                // Count Row
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _countChip(
                      '${order.approvedCount}',
                      'Approved',
                      AppColors.approved,
                      AppColors.approvedLight,
                    ),
                    _countChip(
                      '${order.counterCount}',
                      'Counter',
                      AppColors.counter,
                      AppColors.counterLight,
                    ),
                    _countChip(
                      '${order.rejectedCount}',
                      'Rejected',
                      AppColors.rejected,
                      AppColors.rejectedLight,
                    ),
                    _countChip(
                      '${order.pendingCount}',
                      'Pending',
                      AppColors.textSecondary,
                      AppColors.background,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Gap(12.h),

          // Total Values
          Row(
            children: [
              Expanded(
                child: _valueCard(
                  'Total Order',
                  '₹${order.totalOrderValue.toStringAsFixed(0)}',
                  AppColors.textPrimary,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: _valueCard(
                  'Approved Value',
                  '₹${order.approvedOrderValue.toStringAsFixed(0)}',
                  AppColors.approved,
                ),
              ),
            ],
          ),

          Gap(8.h),

          Text(
            'Submitted ${timeago.format(order.submittedAt)}',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.elasticOut,
        );
  }

  // ═══════════════════════════════════════
  // BULK ACTIONS
  // ═══════════════════════════════════════
  Widget _buildBulkActions(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.adminPrimary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚡ Bulk Actions (${order.pendingCount} pending items)',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.adminPrimary,
            ),
          ),
          Gap(10.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: ElevatedButton.icon(
                    onPressed: _approveAllPending,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approved,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.check_rounded,
                      size: 16.sp,
                      color: AppColors.white,
                    ),
                    label: Text(
                      'Approve All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Gap(10.w),
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: OutlinedButton.icon(
                    onPressed: _rejectAllPending,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.rejected,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16.sp,
                      color: AppColors.rejected,
                    ),
                    label: Text(
                      'Reject All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.rejected,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ═══════════════════════════════════════
  // ITEMS LIST - MAIN SECTION
  // ═══════════════════════════════════════
  Widget _buildItemsList(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Iconsax.box,
                    size: 15.sp,
                    color: AppColors.adminPrimary,
                  ),
                ),
                Gap(10.w),
                Text(
                  '${order.totalItems} Products',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            child: const Divider(height: 1),
          ),

          // Individual Items
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLoading =
                _loadingItems[item.itemId] ?? false;

            return _OrderItemCard(
              item: item,
              index: index,
              isLoading: isLoading,
              isLast: index == order.items.length - 1,
              onApprove: item.isPending
                  ? () => _approveItem(item)
                  : null,
              onCounter: item.isPending
                  ? () => _counterItem(item)
                  : null,
              onReject: item.isPending
                  ? () => _rejectItem(item)
                  : null,
            ).animate().fadeIn(
                  delay: Duration(milliseconds: index * 80),
                );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // CUSTOMER CARD
  // ═══════════════════════════════════════
  Widget _buildCustomerCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.approved.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Iconsax.shop,
                  size: 15.sp,
                  color: AppColors.approved,
                ),
              ),
              Gap(10.w),
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Gap(12.h),
          const Divider(height: 1),
          Gap(12.h),
          _infoRow('Name', order.customerName, bold: true),
          Gap(8.h),
          _infoRow('Business', order.customerBusinessName),
          Gap(8.h),
          _infoRow('City', order.customerCity),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: _infoRow('Phone', order.customerPhone),
              ),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(
                    'tel:${order.customerPhone}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.approved,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.call,
                        size: 14.sp,
                        color: AppColors.white,
                      ),
                      Gap(4.w),
                      Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (order.customerAddress != null) ...[
            Gap(8.h),
            _infoRow('Address', order.customerAddress!),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PAYMENT CARD
  // ═══════════════════════════════════════
  Widget _buildPaymentCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.counter.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Iconsax.money,
                  size: 15.sp,
                  color: AppColors.counter,
                ),
              ),
              Gap(10.w),
              Text(
                'Payment & Delivery',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Gap(12.h),
          const Divider(height: 1),
          Gap(12.h),
          _infoRow(
            'Payment',
            _getPaymentLabel(order.paymentType),
            bold: true,
          ),
          if (order.creditDays != null) ...[
            Gap(8.h),
            _infoRow('Credit Days', '${order.creditDays} days'),
          ],
          if (order.deliveryDate != null) ...[
            Gap(8.h),
            _infoRow(
              'Delivery Date',
              '${order.deliveryDate!.day}/${order.deliveryDate!.month}/${order.deliveryDate!.year}',
            ),
          ],
          if (order.deliveryLocation != null) ...[
            Gap(8.h),
            _infoRow('Location', order.deliveryLocation!),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.adminPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.note_text,
            size: 16.sp,
            color: AppColors.adminPrimary,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trader Note',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.adminPrimary,
                  ),
                ),
                Gap(4.h),
                Text(
                  order.traderNote!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>?> _showItemActionDialog({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool showPriceField = false,
    double? defaultPrice,
  }) async {
    final noteCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: defaultPrice?.toStringAsFixed(0) ?? '',
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 22.sp),
            Gap(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPriceField) ...[
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Final Approved Price (₹)',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Gap(12.h),
            ],
            TextFormField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Note for trader (optional)',
                labelText: 'Admin Note',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'price': showPriceField
                  ? double.tryParse(priceCtrl.text)
                  : null,
              'note': noteCtrl.text.trim().isEmpty
                  ? null
                  : noteCtrl.text.trim(),
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Confirm',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCounterDialog(
    OrderItemModel item,
  ) async {
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              color: AppColors.counter,
              size: 22.sp,
            ),
            Gap(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Counter Offer',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.productName,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reference Prices
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  _refPrice(
                    'Customer Demanded',
                    '₹${item.customerDemandedPrice.toStringAsFixed(0)}',
                    AppColors.pending,
                  ),
                  Gap(4.h),
                  _refPrice(
                    'Current Price',
                    '₹${item.productCurrentPrice.toStringAsFixed(0)}',
                    AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Gap(12.h),
            TextFormField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Your Counter Price (₹) *',
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  color: AppColors.counter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Gap(10.h),
            TextFormField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Reason for counter offer...',
                labelText: 'Note (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text);
              if (price == null || price <= 0) return;
              Navigator.pop(context, {
                'price': price,
                'note': noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.counter,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text(
              'Send Counter',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showRejectDialog(
    OrderItemModel item,
  ) async {
    String? selectedReason;
    final noteCtrl = TextEditingController();

    final reasons = [
      'Price too low',
      'Out of stock',
      'Min order qty not met',
      'Not serviceable',
      'Other',
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Reject: ${item.productName}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map(
                (r) => GestureDetector(
                  onTap: () =>
                      setState(() => selectedReason = r),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: selectedReason == r
                          ? AppColors.rejectedLight
                          : AppColors.background,
                      borderRadius:
                          BorderRadius.circular(8.r),
                      border: Border.all(
                        color: selectedReason == r
                            ? AppColors.rejected
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == r
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16.sp,
                          color: selectedReason == r
                              ? AppColors.rejected
                              : AppColors.border,
                        ),
                        Gap(8.w),
                        Text(
                          r,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: selectedReason == r
                                ? AppColors.rejected
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Gap(8.h),
              TextFormField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Additional note...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(context, {
                        'reason': selectedReason,
                        'note': noteCtrl.text.isEmpty
                            ? null
                            : noteCtrl.text,
                      }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rejected,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message,
    Color color,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────
  Widget _countChip(
    String count,
    String label,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textHint,
            ),
          ),
          Gap(3.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
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
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _refPrice(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => '💵 Full Cash',
      PaymentType.partialPayment => '💳 Partial',
      PaymentType.credit => '📋 Credit',
    };
  }
}

// ═══════════════════════════════════════
// ORDER ITEM CARD (Per Product in Admin View)
// ═══════════════════════════════════════
class _OrderItemCard extends StatelessWidget {
  final OrderItemModel item;
  final int index;
  final bool isLoading;
  final bool isLast;
  final VoidCallback? onApprove;
  final VoidCallback? onCounter;
  final VoidCallback? onReject;

  const _OrderItemCard({
    required this.item,
    required this.index,
    required this.isLoading,
    required this.isLast,
    this.onApprove,
    this.onCounter,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusLabel, statusIcon) =
        switch (item.status) {
      OrderItemStatus.pending => (
          AppColors.pending,
          AppColors.pendingLight,
          'PENDING',
          Iconsax.clock,
        ),
      OrderItemStatus.approved => (
          AppColors.approved,
          AppColors.approvedLight,
          'APPROVED',
          Icons.check_circle_rounded,
        ),
      OrderItemStatus.rejected => (
          AppColors.rejected,
          AppColors.rejectedLight,
          'REJECTED',
          Icons.cancel_rounded,
        ),
      OrderItemStatus.counterOffer => (
          AppColors.counter,
          AppColors.counterLight,
          'COUNTER',
          Icons.compare_arrows_rounded,
        ),
    };

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              // ─── Item Header ──────────────────────────────
              Row(
                children: [
                  // Number
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  // Image
                  if (item.productImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        item.productImage!,
                        width: 38.w,
                        height: 38.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      ),
                    )
                  else
                    _placeholder(),
                  Gap(10.w),
                  // Name + Code
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
                          '${item.productCode} • ${item.quantity.toStringAsFixed(0)} ${item.unit}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 10.sp,
                          color: statusColor,
                        ),
                        Gap(3.w),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Gap(10.h),

              // ─── Price Row ────────────────────────────────
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _priceCol(
                      'Current',
                      '₹${item.productCurrentPrice.toStringAsFixed(0)}',
                      AppColors.textSecondary,
                    ),
                    Container(
                      width: 1,
                      height: 28.h,
                      color: AppColors.border,
                    ),
                    _priceCol(
                      'Demanded',
                      '₹${item.customerDemandedPrice.toStringAsFixed(0)}',
                      AppColors.pending,
                    ),
                    Container(
                      width: 1,
                      height: 28.h,
                      color: AppColors.border,
                    ),
                    _priceCol(
                      'Offered',
                      '₹${item.traderOfferedPrice.toStringAsFixed(0)}',
                      AppColors.adminPrimary,
                    ),
                    if (item.counterPrice != null) ...[
                      Container(
                        width: 1,
                        height: 28.h,
                        color: AppColors.border,
                      ),
                      _priceCol(
                        'Counter',
                        '₹${item.counterPrice!.toStringAsFixed(0)}',
                        AppColors.counter,
                        isBold: true,
                      ),
                    ],
                    if (item.finalPrice != null &&
                        item.isApproved) ...[
                      Container(
                        width: 1,
                        height: 28.h,
                        color: AppColors.border,
                      ),
                      _priceCol(
                        'Final',
                        '₹${item.finalPrice!.toStringAsFixed(0)}',
                        AppColors.approved,
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),

              // Admin note
              if (item.adminNote != null) ...[
                Gap(8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Note: ${item.adminNote}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: statusColor,
                    ),
                  ),
                ),
              ],

              // Rejection reason
              if (item.rejectionReason != null) ...[
                Gap(6.h),
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

              // ─── ACTION BUTTONS (Only for Pending) ───────
              if (item.isPending) ...[
                Gap(10.h),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      // Approve
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 36.h,
                          child: ElevatedButton.icon(
                            onPressed: onApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.approved,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9.r),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            icon: Icon(
                              Icons.check_rounded,
                              size: 14.sp,
                              color: AppColors.white,
                            ),
                            label: Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gap(6.w),
                      // Counter
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 36.h,
                          child: OutlinedButton.icon(
                            onPressed: onCounter,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.counter,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9.r),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            icon: Icon(
                              Icons.compare_arrows_rounded,
                              size: 14.sp,
                              color: AppColors.counter,
                            ),
                            label: Text(
                              'Counter',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.counter,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gap(6.w),
                      // Reject
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 36.h,
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.rejected,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9.r),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.sp,
                              color: AppColors.rejected,
                            ),
                          ),
                        ),
                      ),
                    ],
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
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        Iconsax.box,
        size: 18.sp,
        color: AppColors.textHint,
      ),
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
          style: TextStyle(
            fontSize: 9.sp,
            color: AppColors.textHint,
          ),
        ),
        Gap(3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isBold
                ? FontWeight.w800
                : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
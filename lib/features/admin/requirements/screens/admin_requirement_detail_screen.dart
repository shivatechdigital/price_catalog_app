import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/approve_dialog.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/counter_offer_dialog.dart';
import 'package:price_catalog_app/features/admin/requirements/widgets/reject_dialog.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class AdminRequirementDetailScreen extends ConsumerWidget {
  final RequirementModel requirement;

  const AdminRequirementDetailScreen({super.key, required this.requirement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live document so per-item actions reflect instantly.
    final liveReq = ref.watch(requirementByIdProvider(requirement.id)).value;
    final req = liveReq ?? requirement;

    final hasPendingItems = req.items.any(
      (item) => item.itemStatus == RequirementStatus.pending,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(req),
            Gap(16.h),

            // All Products with per-item actions
            _buildSection(
              title: req.items.length > 1
                  ? 'Products (${req.items.length})'
                  : 'Product Details',
              icon: Iconsax.box,
              child: _buildProductItems(context, ref, req),
            ),
            Gap(16.h),

            // Price Summary
            _buildSection(
              title: 'Price Summary',
              icon: Iconsax.money,
              child: _buildPriceDetails(req),
            ),
            Gap(16.h),

            // Customer Details
            _buildSection(
              title: 'Customer Details',
              icon: Iconsax.shop,
              child: _buildCustomerDetails(context, req),
            ),
            Gap(16.h),

            // Trader Details
            _buildSection(
              title: 'Trader Details',
              icon: Iconsax.people,
              child: _buildTraderDetails(context, req),
            ),
            Gap(16.h),

            // Payment & Delivery
            _buildSection(
              title: 'Payment & Delivery',
              icon: Iconsax.truck,
              child: _buildPaymentDelivery(req),
            ),
            Gap(16.h),

            // Notes
            if (req.traderNote != null || req.adminNote != null)
              _buildSection(
                title: 'Notes',
                icon: Iconsax.note_text,
                child: _buildNotes(req),
              ),

            Gap(16.h),

            // Admin Action Buttons - for ALL pending items at once
            if (hasPendingItems)
              _buildActionButtons(
                context,
                ref,
                req,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            if (req.requiresAdminConfirmation)
              _buildPartialConfirmationButton(context, ref, req),

            // Counter offer response info
            if (req.isCounterOffer) _buildCounterOfferInfo(req),

            Gap(40.h),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════
  AppBar _buildAppBar(BuildContext context) {
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
            'Requirement Detail',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '#${requirement.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(fontSize: 11.sp, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATUS CARD
  // ═══════════════════════════════════════
  Widget _buildStatusCard(RequirementModel req) {
    final (color, icon, label, bgColor) = switch (req.status) {
      RequirementStatus.pending => (
        AppColors.pending,
        Iconsax.clock,
        'Pending Review',
        AppColors.pendingLight,
      ),
      RequirementStatus.approved => (
        AppColors.approved,
        Icons.check_circle_rounded,
        'Approved',
        AppColors.approvedLight,
      ),
      RequirementStatus.rejected => (
        AppColors.rejected,
        Icons.cancel_rounded,
        'Rejected',
        AppColors.rejectedLight,
      ),
      RequirementStatus.counterOffer => (
        AppColors.counter,
        Icons.compare_arrows_rounded,
        'Counter Offer Sent',
        AppColors.counterLight,
      ),
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26.sp, color: color),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Gap(3.h),
                Text(
                  'Submitted ${timeago.format(req.submittedAt)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (req.actionTakenAt != null)
                  Text(
                    'Updated ${timeago.format(req.actionTakenAt!)}',
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
    ).animate().fadeIn().scale(
      begin: const Offset(0.95, 0.95),
      curve: Curves.elasticOut,
    );
  }

  // ═══════════════════════════════════════
  // SECTION WRAPPER
  // ═══════════════════════════════════════
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  child: Icon(icon, size: 15.sp, color: AppColors.adminPrimary),
                ),
                Gap(10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(16.w), child: child),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRODUCT ITEMS - all products with per-item actions
  // ═══════════════════════════════════════
  Widget _buildProductItems(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
  ) {
    return Column(
      children: [
        for (int i = 0; i < req.items.length; i++) ...[
          if (i > 0) ...[
            Gap(12.h),
            Divider(color: AppColors.border, height: 1),
            Gap(12.h),
          ],
          _buildProductItem(context, ref, req, i),
        ],
      ],
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
    int index,
  ) {
    final item = req.items[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: item.productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        item.productImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Iconsax.box, size: 28.sp, color: AppColors.textHint),
            ),
            Gap(14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildItemStatusBadge(item),
                    ],
                  ),
                  Gap(4.h),
                  _buildInfoRow(Iconsax.barcode, item.productCode),
                  if (item.categoryName != null) ...[
                    Gap(2.h),
                    _buildInfoRow(Iconsax.category, item.categoryName!),
                  ],
                ],
              ),
            ),
          ],
        ),
        Gap(10.h),
        _buildDetailRow(
          'Quantity',
          '${item.quantity} ${item.unit}',
          isBold: true,
        ),
        Gap(6.h),
        _buildPriceRow(
          'Admin Price (Current)',
          '₹${item.productCurrentPrice.toStringAsFixed(0)}',
          AppColors.textSecondary,
        ),
        Gap(6.h),
        _buildPriceRow(
          'Customer Demanded',
          '₹${item.customerDemandedPrice.toStringAsFixed(0)}',
          AppColors.pending,
        ),
        Gap(6.h),
        _buildPriceRow(
          'Trader Offered',
          '₹${item.traderOfferedPrice.toStringAsFixed(0)}',
          AppColors.adminPrimary,
        ),
        if (item.itemCounterPrice != null) ...[
          Gap(6.h),
          _buildPriceRow(
            item.counterOfferBy == CounterOfferBy.trader
                ? 'Trader Counter Price'
                : 'Admin Counter Price',
            '₹${item.itemCounterPrice!.toStringAsFixed(0)}',
            AppColors.counter,
            isBold: true,
          ),
        ],
        if (item.itemRejectionReason != null) ...[
          Gap(6.h),
          _buildDetailRow('Rejection Reason', item.itemRejectionReason!),
        ],
        if (item.itemAdminNote != null && item.itemAdminNote!.isNotEmpty) ...[
          Gap(6.h),
          _buildDetailRow('Admin Note', item.itemAdminNote!),
        ],
        if (item.itemTraderResponseNote != null &&
            item.itemTraderResponseNote!.isNotEmpty) ...[
          Gap(6.h),
          _buildDetailRow('Trader Note', item.itemTraderResponseNote!),
        ],

        // Per-item action buttons (only while this item is pending)
        if (item.itemStatus == RequirementStatus.pending ||
            item.isAwaitingAdminResponse) ...[
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _itemActionButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  color: AppColors.approved,
                  filled: true,
                  onTap: () => _approveItem(context, ref, req, index),
                ),
              ),
              Gap(8.w),
              Expanded(
                child: _itemActionButton(
                  label: 'Counter',
                  icon: Icons.compare_arrows_rounded,
                  color: AppColors.counter,
                  onTap: () => _counterItem(context, ref, req, index),
                ),
              ),
              Gap(8.w),
              Expanded(
                child: _itemActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  color: AppColors.rejected,
                  onTap: () => _rejectItem(context, ref, req, index),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildItemStatusBadge(RequirementItemModel item) {
    final (color, label) = switch (item.itemStatus) {
      RequirementStatus.pending => (AppColors.pending, 'Pending'),
      RequirementStatus.approved => (AppColors.approved, 'Approved'),
      RequirementStatus.rejected => (
        AppColors.rejected,
        item.rejectionBy == RejectionBy.trader
            ? 'Rejected by trader'
            : 'Rejected',
      ),
      RequirementStatus.counterOffer => (
        AppColors.counter,
        item.isAwaitingAdminResponse ? 'Trader counter' : 'Counter sent',
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _itemActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      height: 38.h,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              icon: Icon(icon, color: AppColors.white, size: 15.sp),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: Icon(icon, color: color, size: 15.sp),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════
  // PER-ITEM ACTIONS
  // ═══════════════════════════════════════
  // The existing dialogs read product info via the legacy first-item getters,
  // so pass a copy of the requirement holding only the tapped item.
  RequirementModel _singleItemView(RequirementModel req, int index) {
    return req.copyWith(items: [req.items[index]]);
  }

  void _approveItem(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => ApproveDialog(
        requirement: _singleItemView(req, index),
        onApprove: (note, finalPrice) async {
          final success = await ref
              .read(requirementNotifierProvider.notifier)
              .updateItemStatus(
                requirement: req,
                itemIndex: index,
                itemStatus: RequirementStatus.approved,
                counterPrice: finalPrice,
                adminNote: note,
              );
          if (context.mounted) {
            Navigator.pop(context);
            if (success) {
              CustomSnackbar.showSuccess(
                context,
                '${req.items[index].productName} approved!',
              );
            }
          }
        },
      ),
    );
  }

  void _counterItem(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => CounterOfferDialog(
        requirement: _singleItemView(req, index),
        onCounter: (price, note) async {
          final success = await ref
              .read(requirementNotifierProvider.notifier)
              .updateItemStatus(
                requirement: req,
                itemIndex: index,
                itemStatus: RequirementStatus.counterOffer,
                counterPrice: price,
                adminNote: note,
              );
          if (context.mounted) {
            Navigator.pop(context);
            if (success) {
              CustomSnackbar.showSuccess(
                context,
                'Counter offer sent for ${req.items[index].productName}!',
              );
            }
          }
        },
      ),
    );
  }

  void _rejectItem(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => RejectDialog(
        requirement: _singleItemView(req, index),
        onReject: (reason, note) async {
          final success = await ref
              .read(requirementNotifierProvider.notifier)
              .updateItemStatus(
                requirement: req,
                itemIndex: index,
                itemStatus: RequirementStatus.rejected,
                rejectionReason: reason,
                adminNote: note,
              );
          if (context.mounted) {
            Navigator.pop(context);
            if (success) {
              CustomSnackbar.showSuccess(
                context,
                '${req.items[index].productName} rejected',
              );
            }
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRICE SUMMARY
  // ═══════════════════════════════════════
  Widget _buildPriceDetails(RequirementModel req) {
    final approvedCount = req.items.where((i) => i.isApproved).length;
    final rejectedCount = req.items.where((i) => i.isRejected).length;
    final counterCount = req.items.where((i) => i.isCounterOffer).length;
    final pendingCount = req.items
        .where((i) => i.itemStatus == RequirementStatus.pending)
        .length;

    return Column(
      children: [
        _buildPriceRow(
          'Total Products',
          '${req.items.length}',
          AppColors.textSecondary,
        ),
        if (approvedCount > 0) ...[
          Gap(8.h),
          _buildPriceRow('Approved', '$approvedCount', AppColors.approved),
        ],
        if (counterCount > 0) ...[
          Gap(8.h),
          _buildPriceRow('Counter Offered', '$counterCount', AppColors.counter),
        ],
        if (rejectedCount > 0) ...[
          Gap(8.h),
          _buildPriceRow('Rejected', '$rejectedCount', AppColors.rejected),
        ],
        if (pendingCount > 0) ...[
          Gap(8.h),
          _buildPriceRow('Pending', '$pendingCount', AppColors.pending),
        ],
        if (req.counterPrice != null) ...[
          Gap(8.h),
          _buildPriceRow(
            'Admin Counter Price',
            '₹${req.counterPrice!.toStringAsFixed(0)}',
            AppColors.counter,
            isBold: true,
          ),
        ],
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Deal Value',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.white.withOpacity(0.85),
                ),
              ),
              Text(
                '₹${req.totalValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // CUSTOMER DETAILS
  // ═══════════════════════════════════════
  Widget _buildCustomerDetails(BuildContext context, RequirementModel req) {
    return Column(
      children: [
        _buildDetailRow('Name', req.customerName, isBold: true),
        Gap(8.h),
        _buildDetailRow('Business', req.customerBusinessName),
        Gap(8.h),
        _buildDetailRow('City', req.customerCity),
        Gap(8.h),
        // Phone with call button
        Row(
          children: [
            Expanded(child: _buildDetailRow('Phone', req.customerPhone)),
            GestureDetector(
              onTap: () => _callPhone(req.customerPhone),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.approved.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.approved.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.call, size: 14.sp, color: AppColors.approved),
                    Gap(4.w),
                    Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.approved,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (req.customerAddress != null) ...[
          Gap(8.h),
          _buildDetailRow('Address', req.customerAddress!),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════
  // TRADER DETAILS
  // ═══════════════════════════════════════
  Widget _buildTraderDetails(BuildContext context, RequirementModel req) {
    return Column(
      children: [
        _buildDetailRow('Name', req.traderName, isBold: true),
        Gap(8.h),
        _buildDetailRow('Business', req.traderBusinessName),
        Gap(8.h),
        Row(
          children: [
            Expanded(child: _buildDetailRow('Phone', req.traderPhone ?? '')),
            GestureDetector(
              onTap: req.traderPhone != null
                  ? () => _callPhone(req.traderPhone!)
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.adminPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.call,
                      size: 14.sp,
                      color: AppColors.adminPrimary,
                    ),
                    Gap(4.w),
                    Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.adminPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // PAYMENT & DELIVERY
  // ═══════════════════════════════════════
  Widget _buildPaymentDelivery(RequirementModel req) {
    return Column(
      children: [
        _buildDetailRow(
          'Payment Type',
          _getPaymentLabel(req.paymentType),
          isBold: true,
        ),
        if (req.creditDays != null) ...[
          Gap(8.h),
          _buildDetailRow('Credit Days', '${req.creditDays} days'),
        ],
        if (req.advanceAmount != null) ...[
          Gap(8.h),
          _buildDetailRow(
            'Advance Amount',
            '₹${req.advanceAmount!.toStringAsFixed(0)}',
          ),
        ],
        if (req.deliveryDate != null) ...[
          Gap(8.h),
          _buildDetailRow(
            'Delivery Date',
            DateFormat('dd MMM yyyy').format(req.deliveryDate!),
          ),
        ],
        if (req.deliveryLocation != null) ...[
          Gap(8.h),
          _buildDetailRow('Delivery Location', req.deliveryLocation!),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════
  // NOTES
  // ═══════════════════════════════════════
  Widget _buildNotes(RequirementModel req) {
    return Column(
      children: [
        if (req.traderNote != null && req.traderNote!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trader Note',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  req.traderNote!,
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
        if (req.adminNote != null && req.adminNote!.isNotEmpty) ...[
          Gap(10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Note',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  req.adminNote!,
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
      ],
    );
  }

  // ═══════════════════════════════════════
  // ACTION BUTTONS - apply to ALL pending items
  // ═══════════════════════════════════════
  Widget _buildPartialConfirmationButton(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
  ) {
    final approvedCount = req.items.where((item) => item.isApproved).length;
    final rejectedCount = req.items.where((item) => item.isRejected).length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.pending.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.pending.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partial requirement response',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(4.h),
          Text(
            '$approvedCount approved, $rejectedCount rejected by trader. Confirm the remaining products to complete the requirement.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          Gap(12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await ref
                    .read(requirementNotifierProvider.notifier)
                    .confirmPartialRequirement(req);
                if (context.mounted && success) {
                  CustomSnackbar.showSuccess(
                    context,
                    'Remaining products approved.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.approved,
              ),
              icon: const Icon(Icons.check_rounded, color: AppColors.white),
              label: const Text('Approve Remaining Products'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    RequirementModel req,
  ) {
    final pendingCount = req.items
        .where((i) => i.itemStatus == RequirementStatus.pending)
        .length;
    final allLabel = req.items.length > 1
        ? ' All ($pendingCount)'
        : ' Requirement';

    return Column(
      children: [
        // Approve All Button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ApproveDialog(
                requirement: req,
                onApprove: (note, finalPrice) async {
                  final success = await ref
                      .read(requirementNotifierProvider.notifier)
                      .updateAllItemsStatus(
                        requirement: req,
                        itemStatus: RequirementStatus.approved,
                        counterPrice: finalPrice,
                        adminNote: note,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      CustomSnackbar.showSuccess(
                        context,
                        'All pending products approved!',
                      );
                    }
                  }
                },
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.approved,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            icon: Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 20.sp,
            ),
            label: Text(
              'Approve$allLabel',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),

        Gap(10.h),

        Row(
          children: [
            // Counter All Button
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => CounterOfferDialog(
                      requirement: req,
                      onCounter: (price, note) async {
                        final success = await ref
                            .read(requirementNotifierProvider.notifier)
                            .updateAllItemsStatus(
                              requirement: req,
                              itemStatus: RequirementStatus.counterOffer,
                              counterPrice: price,
                              adminNote: note,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            CustomSnackbar.showSuccess(
                              context,
                              'Counter offer sent for all pending products!',
                            );
                          }
                        }
                      },
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.counter),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.compare_arrows_rounded,
                    color: AppColors.counter,
                    size: 18.sp,
                  ),
                  label: Text(
                    req.items.length > 1 ? 'Counter All' : 'Counter Offer',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.counter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            Gap(10.w),

            // Reject All Button
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => RejectDialog(
                      requirement: req,
                      onReject: (reason, note) async {
                        final success = await ref
                            .read(requirementNotifierProvider.notifier)
                            .updateAllItemsStatus(
                              requirement: req,
                              itemStatus: RequirementStatus.rejected,
                              rejectionReason: reason,
                              adminNote: note,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            CustomSnackbar.showSuccess(
                              context,
                              'All pending products rejected',
                            );
                          }
                        }
                      },
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.rejected),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.rejected,
                    size: 18.sp,
                  ),
                  label: Text(
                    req.items.length > 1 ? 'Reject All' : 'Reject',
                    style: TextStyle(
                      fontSize: 13.sp,
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
    );
  }

  // ═══════════════════════════════════════
  // COUNTER OFFER INFO
  // ═══════════════════════════════════════
  Widget _buildCounterOfferInfo(RequirementModel req) {
    final counterItems = req.items.where((i) => i.isCounterOffer).toList();
    final counterText = req.counterPrice != null
        ? 'You offered ₹${req.counterPrice!.toStringAsFixed(0)} as counter price. '
              'Waiting for trader response.'
        : counterItems.isNotEmpty
        ? 'Counter offer sent for ${counterItems.length} '
              'product${counterItems.length > 1 ? 's' : ''}. '
              'Waiting for trader response.'
        : 'Counter offer sent. Waiting for trader response.';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.counterLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.counter.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 18.sp,
                color: AppColors.counter,
              ),
              Gap(8.w),
              Text(
                'Counter Offer Sent',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.counter,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            counterText,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textHint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12.sp, color: AppColors.textHint),
        Gap(4.w),
        Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textHint),
        ),
      ],
    );
  }

  String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => 'Full Cash Payment',
      PaymentType.partialPayment => 'Partial Payment',
      PaymentType.credit => 'Credit Payment',
    };
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

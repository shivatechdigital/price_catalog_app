import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequirementCard extends StatelessWidget {
  final RequirementModel requirement;
  final VoidCallback onTap;

  const RequirementCard({
    super.key,
    required this.requirement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(requirement.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: statusInfo.color.withOpacity(0.2),
          ),
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
            // ═══════════════════════════════════════
            // TOP - Status Bar
            // ═══════════════════════════════════════
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.08),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.color,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusInfo.icon,
                          size: 11.sp,
                          color: AppColors.white,
                        ),
                        Gap(4.w),
                        Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap(8.w),

                  // Req ID
                  Text(
                    '#${requirement.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  // Time
                  Text(
                    timeago.format(requirement.submittedAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // MIDDLE - Main Content
            // ═══════════════════════════════════════
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Product Row
                  Row(
                    children: [
                      // Product Image (+ count badge when multi)
                      Stack(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: requirement.productImage != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10.r),
                                    child: Image.network(
                                      requirement.productImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(
                                        Iconsax.box,
                                        size: 20.sp,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Iconsax.box,
                                    size: 20.sp,
                                    color: AppColors.textHint,
                                  ),
                          ),
                          if (requirement.items.length > 1)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.adminPrimary,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '${requirement.items.length}',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      Gap(12.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              requirement.items.length > 1
                                  ? '${requirement.items.length} Products'
                                  : requirement.productName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Gap(2.h),
                            Text(
                              requirement.items.length > 1
                                  ? _productSummary(
                                      requirement.items,
                                    )
                                  : '${requirement.quantity} ${requirement.unit} • ${requirement.productCode}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),

                  Gap(14.h),

                  // Price Row
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _buildPriceItem(
                          label: 'Current Price',
                          value:
                              '₹${requirement.productCurrentPrice.toStringAsFixed(0)}',
                          color: AppColors.textSecondary,
                        ),
                        Container(
                          width: 1,
                          height: 30.h,
                          color: AppColors.border,
                        ),
                        _buildPriceItem(
                          label: 'Customer Demand',
                          value:
                              '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
                          color: AppColors.pending,
                        ),
                        Container(
                          width: 1,
                          height: 30.h,
                          color: AppColors.border,
                        ),
                        _buildPriceItem(
                          label: 'Trader Offer',
                          value:
                              '₹${requirement.traderOfferedPrice.toStringAsFixed(0)}',
                          color: AppColors.adminPrimary,
                        ),
                      ],
                    ),
                  ),

                  Gap(12.h),

                  // Trader + Customer Row
                  Row(
                    children: [
                      // Trader
                      Expanded(
                        child: _buildPersonChip(
                          icon: Iconsax.people,
                          label: requirement.traderName,
                          subLabel: 'Trader',
                          color: AppColors.adminPrimary,
                        ),
                      ),
                      Gap(8.w),
                      // Customer
                      Expanded(
                        child: _buildPersonChip(
                          icon: Iconsax.shop,
                          label: requirement.customerName,
                          subLabel: requirement.customerCity,
                          color: AppColors.traderPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Counter price (if any)
                  if (requirement.counterPrice != null) ...[
                    Gap(10.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.counterLight,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.counter.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.compare_arrows_rounded,
                            size: 14.sp,
                            color: AppColors.counter,
                          ),
                          Gap(6.w),
                          Text(
                            'Counter Offer: ₹${requirement.counterPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.counter,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Trader Note
                  if (requirement.traderNote != null &&
                      requirement.traderNote!.isNotEmpty) ...[
                    Gap(10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Iconsax.note_text,
                            size: 14.sp,
                            color: AppColors.textHint,
                          ),
                          Gap(6.w),
                          Expanded(
                            child: Text(
                              requirement.traderNote!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // BOTTOM - Payment Info
            // ═══════════════════════════════════════
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.money,
                    size: 14.sp,
                    color: AppColors.textHint,
                  ),
                  Gap(6.w),
                  Text(
                    _getPaymentLabel(requirement.paymentType),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ₹${requirement.totalValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem({
    required String label,
    required String value,
    required Color color,
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
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonChip({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          Gap(6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => '💵 Full Cash Payment',
      PaymentType.partialPayment => '💳 Partial Payment',
      PaymentType.credit => '📋 Credit Payment',
    };
  }

  String _productSummary(List<RequirementItemModel> items) {
    if (items.length <= 2) {
      return items.map((i) => i.productName).join(' • ');
    }
    return '${items[0].productName} • +${items.length - 1} more';
  }

  ({Color color, IconData icon, String label}) _getStatusInfo(
    RequirementStatus status,
  ) {
    return switch (status) {
      RequirementStatus.pending => (
          color: AppColors.pending,
          icon: Iconsax.clock,
          label: 'PENDING'
        ),
      RequirementStatus.approved => (
          color: AppColors.approved,
          icon: Icons.check_rounded,
          label: 'APPROVED'
        ),
      RequirementStatus.rejected => (
          color: AppColors.rejected,
          icon: Icons.close_rounded,
          label: 'REJECTED'
        ),
      RequirementStatus.counterOffer => (
          color: AppColors.counter,
          icon: Icons.compare_arrows_rounded,
          label: 'COUNTER OFFER'
        ),
    };
  }
}
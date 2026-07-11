import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class TraderRequirementDetailScreen extends ConsumerStatefulWidget {
  final RequirementModel requirement;

  const TraderRequirementDetailScreen({
    super.key,
    required this.requirement,
  });

  @override
  ConsumerState<TraderRequirementDetailScreen> createState() =>
      _TraderRequirementDetailScreenState();
}

class _TraderRequirementDetailScreenState
    extends ConsumerState<TraderRequirementDetailScreen> {
  bool _isAccepting = false;
  bool _isRejecting = false;

  // ═══════════════════════════════════════
  // ACCEPT COUNTER OFFER
  // ═══════════════════════════════════════
  Future<void> _acceptCounter() async {
    setState(() => _isAccepting = true);
    try {
      final success = await ref
          .read(requirementNotifierProvider.notifier)
          .acceptCounterOffer(widget.requirement.id);

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        CustomSnackbar.showSuccess(
          context,
          '✅ Counter offer accepted! Admin will be notified.',
        );
      } else {
        CustomSnackbar.showError(context, 'Failed to accept. Try again.');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  // ═══════════════════════════════════════
  // REJECT COUNTER OFFER
  // ═══════════════════════════════════════
  Future<void> _rejectCounter() async {
    setState(() => _isRejecting = true);
    try {
      final success = await ref
          .read(requirementNotifierProvider.notifier)
          .rejectCounterOffer(widget.requirement.id);

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        CustomSnackbar.showSuccess(
          context,
          'Counter offer rejected.',
        );
      } else {
        CustomSnackbar.showError(context, 'Failed to reject. Try again.');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  // ═══════════════════════════════════════
  // CALL PHONE
  // ═══════════════════════════════════════
  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requirement;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════
          // APP BAR
          // ═══════════════════════════════════════
          _buildSliverAppBar(req),

          // ═══════════════════════════════════════
          // BODY CONTENT
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: Column(
              children: [
                Gap(16.h),

                // 1. STATUS TIMELINE
                _buildStatusTimeline(req)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),

                Gap(12.h),

                // 2. PRODUCT DETAILS
                _buildSection(
                  title: 'Product Details',
                  icon: Iconsax.box,
                  iconColor: AppColors.adminPrimary,
                  child: _buildProductDetails(req),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                Gap(12.h),

                // 3. PRICE BREAKDOWN
                _buildSection(
                  title: 'Price Breakdown',
                  icon: Iconsax.money,
                  iconColor: AppColors.traderPrimary,
                  child: _buildPriceBreakdown(req),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                Gap(12.h),

                // 4. CUSTOMER DETAILS
                _buildSection(
                  title: 'Customer Details',
                  icon: Iconsax.shop,
                  iconColor: AppColors.approved,
                  child: _buildCustomerDetails(req),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                Gap(12.h),

                // 5. PAYMENT & DELIVERY
                _buildSection(
                  title: 'Payment & Delivery',
                  icon: Iconsax.truck,
                  iconColor: AppColors.counter,
                  child: _buildPaymentDelivery(req),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                Gap(12.h),

                // 6. NOTES (if any)
                if ((req.traderNote != null &&
                        req.traderNote!.isNotEmpty) ||
                    (req.adminNote != null &&
                        req.adminNote!.isNotEmpty))
                  _buildSection(
                    title: 'Notes',
                    icon: Iconsax.note_text,
                    iconColor: AppColors.textSecondary,
                    child: _buildNotes(req),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                Gap(12.h),

                // 7. COUNTER OFFER CARD (if applicable)
                if (req.isCounterOffer)
                  _buildCounterOfferCard(req)
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.elasticOut,
                      ),

                // 8. REJECTION REASON (if rejected)
                if (req.isRejected &&
                    req.rejectionReason != null)
                  _buildRejectionCard(req)
                      .animate()
                      .fadeIn(delay: 400.ms),

                Gap(100.h),
              ],
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════
      // BOTTOM ACTION BAR
      // ═══════════════════════════════════════
      bottomNavigationBar: req.isCounterOffer
          ? _buildCounterActionBar()
          : null,
    );
  }

  // ═══════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════
  Widget _buildSliverAppBar(RequirementModel req) {
    final statusInfo = _getStatusInfo(req.status);

    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: statusInfo.color,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.sp,
            color: AppColors.white,
          ),
        ),
      ),
      actions: [
        // Copy Req ID
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: req.id));
            CustomSnackbar.showSuccess(
              context,
              'Requirement ID copied!',
            );
          },
          child: Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.copy,
                  size: 14.sp,
                  color: AppColors.white,
                ),
                Gap(4.w),
                Text(
                  'Copy ID',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusInfo.color,
                statusInfo.color.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusInfo.icon,
                          size: 12.sp,
                          color: AppColors.white,
                        ),
                        Gap(6.w),
                        Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap(10.h),

                  // Product Name - BIG
                  Text(
                    req.productName,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Gap(6.h),

                  // Req ID + Time
                  Row(
                    children: [
                      Icon(
                        Iconsax.document,
                        size: 12.sp,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      Gap(4.w),
                      Text(
                        '#${req.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(12.w),
                      Icon(
                        Iconsax.clock,
                        size: 12.sp,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      Gap(4.w),
                      Text(
                        timeago.format(req.submittedAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATUS TIMELINE
  // ═══════════════════════════════════════
  Widget _buildStatusTimeline(RequirementModel req) {
    final steps = [
      _TimelineStep(
        label: 'Submitted',
        icon: Iconsax.send_1,
        date: req.submittedAt,
        isDone: true,
        color: AppColors.adminPrimary,
      ),
      _TimelineStep(
        label: req.isApproved
            ? 'Approved'
            : req.isRejected
                ? 'Rejected'
                : req.isCounterOffer
                    ? 'Counter Offer'
                    : 'Under Review',
        icon: req.isApproved
            ? Icons.check_circle_rounded
            : req.isRejected
                ? Icons.cancel_rounded
                : req.isCounterOffer
                    ? Icons.compare_arrows_rounded
                    : Iconsax.clock,
        date: req.actionTakenAt,
        isDone: !req.isPending,
        color: req.isApproved
            ? AppColors.approved
            : req.isRejected
                ? AppColors.rejected
                : req.isCounterOffer
                    ? AppColors.counter
                    : AppColors.textHint,
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Circle
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: step.isDone
                              ? step.color
                              : AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: step.isDone
                                ? step.color
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          step.icon,
                          size: 18.sp,
                          color: step.isDone
                              ? AppColors.white
                              : AppColors.textHint,
                        ),
                      ),
                      Gap(6.h),
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: step.isDone
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: step.isDone
                              ? step.color
                              : AppColors.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (step.date != null)
                        Text(
                          DateFormat('dd MMM, hh:mm a')
                              .format(step.date!),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                // Connector Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(bottom: 28.h),
                      color: steps[index + 1].isDone
                          ? steps[index + 1].color
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SECTION WRAPPER
  // ═══════════════════════════════════════
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 16.sp, color: iconColor),
                ),
                Gap(10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            child: const Divider(height: 1),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: child,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // 1. PRODUCT DETAILS
  // ═══════════════════════════════════════
  Widget _buildProductDetails(RequirementModel req) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image or Icon
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: AppColors.traderPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.traderPrimary.withOpacity(0.15),
                ),
              ),
              child: req.productImage != null &&
                      req.productImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        req.productImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Iconsax.box,
                          size: 32.sp,
                          color: AppColors.traderPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      Iconsax.box,
                      size: 32.sp,
                      color: AppColors.traderPrimary,
                    ),
            ),

            Gap(14.w),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    req.productName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),

                  Gap(6.h),

                  // Product Code
                  _iconTextRow(
                    icon: Iconsax.barcode,
                    text: req.productCode,
                    color: AppColors.textSecondary,
                  ),

                  Gap(4.h),

                  // Category
                  if (req.categoryName != null)
                    _iconTextRow(
                      icon: Iconsax.category,
                      text: req.categoryName!,
                      color: AppColors.adminPrimary,
                    ),
                ],
              ),
            ),
          ],
        ),

        Gap(14.h),

        // Quantity Row
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.traderPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.traderPrimary.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.weight,
                size: 16.sp,
                color: AppColors.traderPrimary,
              ),
              Gap(8.w),
              Text(
                'Quantity Required: ',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${req.quantity.toStringAsFixed(req.quantity % 1 == 0 ? 0 : 1)} ${req.unit.toUpperCase()}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.traderPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 2. PRICE BREAKDOWN
  // ═══════════════════════════════════════
  Widget _buildPriceBreakdown(RequirementModel req) {
    return Column(
      children: [
        // Price Grid
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Price Type',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              _priceRow(
                label: 'Admin Listed Price',
                value:
                    '₹${req.productCurrentPrice.toStringAsFixed(0)}',
                color: AppColors.textSecondary,
                icon: Iconsax.tag,
              ),

              const Divider(height: 1),

              _priceRow(
                label: 'Customer Demanded',
                value:
                    '₹${req.customerDemandedPrice.toStringAsFixed(0)}',
                color: AppColors.pending,
                icon: Iconsax.money_recive,
                isHighlighted: true,
              ),

              const Divider(height: 1),

              _priceRow(
                label: 'Your Offered Price',
                value:
                    '₹${req.traderOfferedPrice.toStringAsFixed(0)}',
                color: AppColors.adminPrimary,
                icon: Iconsax.money_send,
              ),

              if (req.counterPrice != null) ...[
                const Divider(height: 1),
                _priceRow(
                  label: 'Admin Counter Price',
                  value:
                      '₹${req.counterPrice!.toStringAsFixed(0)}',
                  color: AppColors.counter,
                  icon: Icons.compare_arrows_rounded,
                  isHighlighted: true,
                ),
              ],
            ],
          ),
        ),

        Gap(12.h),

        // Total Value
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            gradient: AppColors.traderGradient,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.traderPrimary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Deal Value',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${req.quantity.toStringAsFixed(0)} ${req.unit} × ₹${req.agreedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${req.totalValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22.sp,
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
  // 3. CUSTOMER DETAILS
  // ═══════════════════════════════════════
  Widget _buildCustomerDetails(RequirementModel req) {
    return Column(
      children: [
        // Customer Name + Business
        _detailRow(
          icon: Iconsax.user,
          label: 'Customer Name',
          value: req.customerName,
          isBold: true,
        ),

        Gap(12.h),

        _detailRow(
          icon: Iconsax.building,
          label: 'Business Name',
          value: req.customerBusinessName,
        ),

        Gap(12.h),

        _detailRow(
          icon: Iconsax.location,
          label: 'City',
          value: req.customerCity,
        ),

        if (req.customerAddress != null &&
            req.customerAddress!.isNotEmpty) ...[
          Gap(12.h),
          _detailRow(
            icon: Iconsax.map,
            label: 'Address',
            value: req.customerAddress!,
          ),
        ],

        Gap(12.h),

        // Phone with Call Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.approved.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Iconsax.call,
                size: 15.sp,
                color: AppColors.approved,
              ),
            ),
            Gap(10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  req.customerPhone,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _callPhone(req.customerPhone),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.approved,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.approved.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
      ],
    );
  }

  // ═══════════════════════════════════════
  // 4. PAYMENT & DELIVERY
  // ═══════════════════════════════════════
  Widget _buildPaymentDelivery(RequirementModel req) {
    return Column(
      children: [
        // Payment Type
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.counter.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Iconsax.money,
                  size: 20.sp,
                  color: AppColors.counter,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Type',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      _getPaymentLabel(req.paymentType),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Credit Days
        if (req.creditDays != null) ...[
          Gap(10.h),
          _detailRow(
            icon: Iconsax.calendar,
            label: 'Credit Days',
            value: '${req.creditDays} days',
          ),
        ],

        // Advance Amount
        if (req.advanceAmount != null &&
            req.advanceAmount! > 0) ...[
          Gap(10.h),
          _detailRow(
            icon: Iconsax.wallet,
            label: 'Advance Amount',
            value:
                '₹${req.advanceAmount!.toStringAsFixed(0)}',
          ),
        ],

        // Delivery Date
        if (req.deliveryDate != null) ...[
          Gap(10.h),
          _detailRow(
            icon: Iconsax.truck,
            label: 'Expected Delivery',
            value: DateFormat('dd MMMM yyyy')
                .format(req.deliveryDate!),
            isBold: true,
          ),
        ],

        // Delivery Location
        if (req.deliveryLocation != null &&
            req.deliveryLocation!.isNotEmpty) ...[
          Gap(10.h),
          _detailRow(
            icon: Iconsax.location,
            label: 'Delivery Location',
            value: req.deliveryLocation!,
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════
  // 5. NOTES
  // ═══════════════════════════════════════
  Widget _buildNotes(RequirementModel req) {
    return Column(
      children: [
        // Trader Note
        if (req.traderNote != null &&
            req.traderNote!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.traderPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.traderPrimary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.note_text,
                      size: 14.sp,
                      color: AppColors.traderPrimary,
                    ),
                    Gap(6.w),
                    Text(
                      'Your Note',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.traderPrimary,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
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

        // Admin Note
        if (req.adminNote != null &&
            req.adminNote!.isNotEmpty) ...[
          if (req.traderNote != null) Gap(10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.adminPrimary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.message,
                      size: 14.sp,
                      color: AppColors.adminPrimary,
                    ),
                    Gap(6.w),
                    Text(
                      'Admin Note',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.adminPrimary,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
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
  // COUNTER OFFER CARD
  // ═══════════════════════════════════════
  Widget _buildCounterOfferCard(RequirementModel req) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.counter.withOpacity(0.15),
            AppColors.counter.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.counter.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.counter,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  size: 20.sp,
                  color: AppColors.white,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Counter Offer Received!',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.counter,
                      ),
                    ),
                    Text(
                      'Admin has suggested a new price',
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

          Gap(16.h),

          // Price Comparison
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _counterPriceItem(
                      label: 'You Demanded',
                      value:
                          '₹${req.customerDemandedPrice.toStringAsFixed(0)}',
                      color: AppColors.textSecondary,
                    ),
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppColors.counter.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16.sp,
                        color: AppColors.counter,
                      ),
                    ),
                    _counterPriceItem(
                      label: 'Admin Counter',
                      value:
                          '₹${req.counterPrice!.toStringAsFixed(0)}',
                      color: AppColors.counter,
                      isBig: true,
                    ),
                  ],
                ),

                Gap(10.h),

                // Difference
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.counter.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        req.counterPrice! >
                                req.customerDemandedPrice
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14.sp,
                        color: AppColors.counter,
                      ),
                      Gap(4.w),
                      Text(
                        'Difference: ₹${(req.counterPrice! - req.customerDemandedPrice).abs().toStringAsFixed(0)} ${req.counterPrice! > req.customerDemandedPrice ? 'higher' : 'lower'} than your demand',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.counter,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Gap(12.h),

          Text(
            '⚠️ Please respond to the counter offer.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // REJECTION CARD
  // ═══════════════════════════════════════
  Widget _buildRejectionCard(RequirementModel req) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.rejectedLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.rejected.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_rounded,
                size: 20.sp,
                color: AppColors.rejected,
              ),
              Gap(8.w),
              Text(
                'Rejection Reason',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rejected,
                ),
              ),
            ],
          ),
          Gap(10.h),
          Text(
            req.rejectionReason!,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // COUNTER OFFER ACTION BAR
  // ═══════════════════════════════════════
  Widget _buildCounterActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            'Respond to Counter Offer',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          Gap(12.h),

          Row(
            children: [
              // Reject Button
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isRejecting || _isAccepting
                            ? null
                            : () => _showRejectConfirmDialog(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.rejected,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: _isRejecting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.rejected,
                            ),
                          )
                        : Icon(
                            Icons.close_rounded,
                            size: 18.sp,
                            color: AppColors.rejected,
                          ),
                    label: Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rejected,
                      ),
                    ),
                  ),
                ),
              ),

              Gap(12.w),

              // Accept Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isAccepting || _isRejecting
                            ? null
                            : () => _showAcceptConfirmDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approved,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    icon: _isAccepting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Icon(
                            Icons.check_rounded,
                            size: 18.sp,
                            color: AppColors.white,
                          ),
                    label: Text(
                      'Accept Counter ✅',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // CONFIRM DIALOGS
  // ═══════════════════════════════════════
  void _showAcceptConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.approved,
              size: 24.sp,
            ),
            Gap(8.w),
            Text(
              'Accept Counter Offer?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You are accepting ₹${widget.requirement.counterPrice!.toStringAsFixed(0)} as the final price for ${widget.requirement.productName}.',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptCounter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.approved,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Yes, Accept',
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

  void _showRejectConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_rounded,
              color: AppColors.rejected,
              size: 24.sp,
            ),
            Gap(8.w),
            Text(
              'Reject Counter Offer?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reject the counter offer of ₹${widget.requirement.counterPrice!.toStringAsFixed(0)}?',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCounter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rejected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Yes, Reject',
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

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════
  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.sp, color: AppColors.textSecondary),
        ),
        Gap(10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
              Gap(2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      color: isHighlighted
          ? color.withOpacity(0.04)
          : Colors.transparent,
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          Gap(8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: isHighlighted
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconTextRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12.sp, color: color),
        Gap(4.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _counterPriceItem({
    required String label,
    required String value,
    required Color color,
    bool isBig = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textHint,
          ),
        ),
        Gap(4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: isBig ? 20.sp : 16.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // STATUS INFO HELPER
  // ═══════════════════════════════════════
  ({Color color, IconData icon, String label}) _getStatusInfo(
    RequirementStatus status,
  ) {
    return switch (status) {
      RequirementStatus.pending => (
          color: AppColors.pending,
          icon: Iconsax.clock,
          label: 'PENDING REVIEW',
        ),
      RequirementStatus.approved => (
          color: AppColors.approved,
          icon: Icons.check_circle_rounded,
          label: 'APPROVED ✅',
        ),
      RequirementStatus.rejected => (
          color: AppColors.rejected,
          icon: Icons.cancel_rounded,
          label: 'REJECTED ❌',
        ),
      RequirementStatus.counterOffer => (
          color: AppColors.counter,
          icon: Icons.compare_arrows_rounded,
          label: 'COUNTER OFFER 🔄',
        ),
    };
  }

  String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => '💵 Full Cash Payment',
      PaymentType.partialPayment => '💳 Partial Payment',
      PaymentType.credit => '📋 Credit Payment',
    };
  }
}

// ═══════════════════════════════════════
// TIMELINE STEP MODEL
// ═══════════════════════════════════════
class _TimelineStep {
  final String label;
  final IconData icon;
  final DateTime? date;
  final bool isDone;
  final Color color;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.date,
    required this.isDone,
    required this.color,
  });
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class PriceUpdateScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const PriceUpdateScreen({super.key, required this.product});

  @override
  ConsumerState<PriceUpdateScreen> createState() =>
      _PriceUpdateScreenState();
}

class _PriceUpdateScreenState
    extends ConsumerState<PriceUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _dealerPriceController;
  late final TextEditingController _minPriceController;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product.currentPrice;
    _purchasePriceController = TextEditingController(
      text: p.purchasePrice.toStringAsFixed(0),
    );
    _sellingPriceController = TextEditingController(
      text: p.sellingPrice.toStringAsFixed(0),
    );
    _dealerPriceController = TextEditingController(
      text: p.dealerPrice.toStringAsFixed(0),
    );
    _minPriceController = TextEditingController(
      text: (p.minAcceptedPrice ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _dealerPriceController.dispose();
    _minPriceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // UPDATE PRICE
  // ═══════════════════════════════════════
  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final currentUser = ref.read(currentUserProvider);

    final newPrice = PriceModel(
      purchasePrice: double.parse(_purchasePriceController.text),
      sellingPrice: double.parse(_sellingPriceController.text),
      dealerPrice: double.parse(_dealerPriceController.text),
      minAcceptedPrice: _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null,
      updatedAt: DateTime.now(),
      updatedBy: currentUser?.uid ?? '',
    );

    try {
      await ref.read(productRepositoryProvider).updatePrice(
            productId: widget.product.id,
            productName: widget.product.name,
            newPrice: newPrice,
            oldPrice: widget.product.currentPrice,
            updatedBy: currentUser?.uid ?? '',
            updatedByName: currentUser?.name ?? '',
            changeReason: _reasonController.text.trim(),
          );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      CustomSnackbar.showSuccess(
        context,
        'Price updated successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.showError(
        context,
        'Failed to update price. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        title: Text(
          'Update Price',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              _buildProductInfoCard(),

              Gap(20.h),

              // Old vs New Prices
              _buildOldPricesCard(),

              Gap(20.h),

              // New Prices Form
              _buildNewPricesForm(),

              Gap(20.h),

              // Reason
              _buildReasonField(),

              Gap(32.h),

              // Save Button
              CustomButton(
                label: 'Update Price',
                isLoading: _isLoading,
                gradient: AppColors.adminGradient,
                prefixIcon: Iconsax.money_recive,
                onPressed: _updatePrice,
              ),

              Gap(20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRODUCT INFO CARD
  // ═══════════════════════════════════════
  Widget _buildProductInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: widget.product.primaryImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      widget.product.primaryImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Iconsax.box,
                    size: 24.sp,
                    color: AppColors.adminPrimary,
                  ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Gap(3.h),
                Text(
                  '${widget.product.productCode} • ${widget.product.categoryName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════
  // OLD PRICES CARD
  // ═══════════════════════════════════════
  Widget _buildOldPricesCard() {
    final old = widget.product.currentPrice;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: 14.sp,
                color: AppColors.textHint,
              ),
              Gap(6.w),
              Text(
                'Current Prices',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOldPriceItem(
                'Purchase',
                '₹${old.purchasePrice.toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 36.h,
                color: AppColors.border,
              ),
              _buildOldPriceItem(
                'Selling',
                '₹${old.sellingPrice.toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 36.h,
                color: AppColors.border,
              ),
              _buildOldPriceItem(
                'Dealer',
                '₹${old.dealerPrice.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOldPriceItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textHint,
          ),
        ),
        Gap(4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // NEW PRICES FORM
  // ═══════════════════════════════════════
  Widget _buildNewPricesForm() {
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
            'New Prices',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(16.h),

          // Purchase Price
          _buildPriceRow(
            label: 'Purchase Price',
            controller: _purchasePriceController,
            color: AppColors.rejected,
            icon: Iconsax.wallet,
          ),
          Gap(12.h),

          // Selling Price
          _buildPriceRow(
            label: 'Selling Price',
            controller: _sellingPriceController,
            color: AppColors.textPrimary,
            icon: Iconsax.money,
          ),
          Gap(12.h),

          // Dealer Price
          _buildPriceRow(
            label: 'Dealer Price',
            controller: _dealerPriceController,
            color: AppColors.adminPrimary,
            icon: Iconsax.people,
          ),
          Gap(12.h),

          // Min Price
          _buildPriceRow(
            label: 'Min Accepted Price',
            controller: _minPriceController,
            color: AppColors.counter,
            icon: Iconsax.arrow_down,
            isRequired: false,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPriceRow({
    required String label,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
    bool isRequired = true,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: color),
        ),
        Gap(12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 120.w,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            validator: isRequired
                ? (v) {
                    if (v == null || v.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // REASON FIELD
  // ═══════════════════════════════════════
  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Price Change',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'e.g. Market rate increase, supplier change...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 44.h),
              child: Icon(
                Iconsax.note_text,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}
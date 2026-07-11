import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class SubmitRequirementScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const SubmitRequirementScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<SubmitRequirementScreen> createState() =>
      _SubmitRequirementScreenState();
}

class _SubmitRequirementScreenState
    extends ConsumerState<SubmitRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Customer Detail Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerBusinessController = TextEditingController();
  final _customerCityController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // Quantity Controllers
  final _quantityController = TextEditingController();

  // Price Controllers
  final _demandedPriceController = TextEditingController();
  final _offeredPriceController = TextEditingController();

  // Delivery
  final _deliveryLocationController = TextEditingController();
  final _noteController = TextEditingController();

  // State
  PaymentType _selectedPayment = PaymentType.fullCash;
  int? _creditDays;
  DateTime? _deliveryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill offered price with selling price
    _offeredPriceController.text = widget.product.currentPrice
        .sellingPrice
        .toStringAsFixed(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerBusinessController.dispose();
    _customerCityController.dispose();
    _customerAddressController.dispose();
    _quantityController.dispose();
    _demandedPriceController.dispose();
    _offeredPriceController.dispose();
    _deliveryLocationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // SUBMIT
  // ═══════════════════════════════════════
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final currentUser = ref.read(currentUserProvider);

    final success = await ref
        .read(requirementNotifierProvider.notifier)
        .submitRequirement(
          traderId: currentUser?.uid ?? '',
          traderName: currentUser?.name ?? '',
          traderBusinessName: currentUser?.businessName ?? '',
          traderPhone: currentUser?.phone ?? '',
          productId: widget.product.id,
          productName: widget.product.name,
          productCode: widget.product.productCode,
          productImage: widget.product.primaryImage.isNotEmpty
              ? widget.product.primaryImage
              : null,
          categoryName: widget.product.categoryName,
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          customerBusinessName:
              _customerBusinessController.text.trim(),
          customerCity: _customerCityController.text.trim(),
          customerAddress:
              _customerAddressController.text.trim().isEmpty
                  ? null
                  : _customerAddressController.text.trim(),
          quantity: double.parse(_quantityController.text),
          unit: widget.product.unit,
          productCurrentPrice:
              widget.product.currentPrice.sellingPrice,
          customerDemandedPrice:
              double.parse(_demandedPriceController.text),
          traderOfferedPrice:
              double.parse(_offeredPriceController.text),
          paymentType: _selectedPayment,
          creditDays: _creditDays,
          deliveryDate: _deliveryDate,
          deliveryLocation:
              _deliveryLocationController.text.trim().isEmpty
                  ? null
                  : _deliveryLocationController.text.trim(),
          traderNote: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      CustomSnackbar.showSuccess(
        context,
        '✅ Requirement submitted! Waiting for admin approval.',
      );
    } else {
      CustomSnackbar.showError(
        context,
        'Failed to submit. Please try again.',
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
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
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
          'Submit Requirement',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Product Info Bar
            _buildProductInfoBar(),

            // Step Indicator
            _buildStepIndicator(),

            // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) =>
                    setState(() => _currentStep = i),
                children: [
                  _buildStep1CustomerDetails(),
                  _buildStep2PriceQuantity(),
                  _buildStep3PaymentDelivery(),
                ],
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // PRODUCT INFO BAR
  // ═══════════════════════════════════════
  Widget _buildProductInfoBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.traderPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.traderPrimary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: widget.product.primaryImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.network(
                        widget.product.primaryImage,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Iconsax.box,
                      size: 22.sp,
                      color: AppColors.traderPrimary,
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${widget.product.productCode} • ${widget.product.categoryName}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${widget.product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.traderPrimary,
                  ),
                ),
                Text(
                  '/${widget.product.unit}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP INDICATOR
  // ═══════════════════════════════════════
  Widget _buildStepIndicator() {
    final steps = [
      'Customer Info',
      'Price & Qty',
      'Payment',
    ];

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final index = e.key;
          final label = e.value;
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 300,
                        ),
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.traderPrimary
                              : AppColors.border,
                          borderRadius:
                              BorderRadius.circular(10.r),
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isActive
                              ? AppColors.traderPrimary
                              : AppColors.textHint,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) Gap(6.w),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 1 - CUSTOMER DETAILS
  // ═══════════════════════════════════════
  Widget _buildStep1CustomerDetails() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Customer Details',
            'Who is buying this product?',
            Iconsax.shop,
          ),

          Gap(20.h),

          _buildLabel('Customer / Shopkeeper Name *'),
          Gap(8.h),
          TextFormField(
            controller: _customerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Mahesh Hardware Store',
              prefixIcon: Icon(
                Iconsax.user,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'Customer name is required'
                    : null,
          ),

          Gap(16.h),

          _buildLabel('Customer Phone *'),
          Gap(8.h),
          TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '10 digit number',
              counterText: '',
              prefixText: '+91  ',
              prefixStyle: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
              prefixIcon: Icon(
                Iconsax.call,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Phone is required';
              }
              if (v.length < 10) {
                return 'Enter valid 10 digit number';
              }
              return null;
            },
          ),

          Gap(16.h),

          _buildLabel('Business Name *'),
          Gap(8.h),
          TextFormField(
            controller: _customerBusinessController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Mahesh Hardware & Traders',
              prefixIcon: Icon(
                Iconsax.building,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'Business name is required'
                    : null,
          ),

          Gap(16.h),

          _buildLabel('City *'),
          Gap(8.h),
          TextFormField(
            controller: _customerCityController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Pune',
              prefixIcon: Icon(
                Iconsax.location,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'City is required'
                    : null,
          ),

          Gap(16.h),

          _buildLabel('Address (Optional)'),
          Gap(8.h),
          TextFormField(
            controller: _customerAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Shop address...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 28.h),
                child: Icon(
                  Iconsax.map,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),

          Gap(20.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 2 - PRICE & QUANTITY
  // ═══════════════════════════════════════
  Widget _buildStep2PriceQuantity() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Price & Quantity',
            'Enter deal details',
            Iconsax.money,
          ),

          Gap(20.h),

          // Quantity
          _buildLabel(
              'Quantity Required (${widget.product.unit}) *'),
          Gap(8.h),
          TextFormField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 10',
              prefixIcon: Icon(
                Iconsax.weight,
                size: 20.sp,
                color: AppColors.textHint,
              ),
              suffixText: widget.product.unit.toUpperCase(),
              suffixStyle: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Quantity is required';
              }
              if (double.tryParse(v) == null ||
                  double.parse(v) <= 0) {
                return 'Enter valid quantity';
              }
              return null;
            },
          ),

          Gap(16.h),

          // Current price info
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 14.sp,
                  color: AppColors.textHint,
                ),
                Gap(6.w),
                Text(
                  'Current price: ₹${widget.product.currentPrice.sellingPrice.toStringAsFixed(0)}/${widget.product.unit}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Gap(16.h),

          // Customer Demanded Price
          _buildLabel('Customer Demanded Price (₹) *'),
          Gap(4.h),
          Text(
            'Price customer is willing to pay',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
          Gap(8.h),
          TextFormField(
            controller: _demandedPriceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 62000',
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.pending,
              ),
              prefixIcon: Icon(
                Iconsax.money_recive,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Customer price is required';
              }
              return null;
            },
          ),

          Gap(16.h),

          // Trader Offered Price
          _buildLabel('Your Offered Price (₹) *'),
          Gap(4.h),
          Text(
            'Price you will offer to the customer',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
          Gap(8.h),
          TextFormField(
            controller: _offeredPriceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 65000',
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.adminPrimary,
              ),
              prefixIcon: Icon(
                Iconsax.money_send,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Your price is required';
              }
              return null;
            },
          ),

          Gap(20.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 3 - PAYMENT & DELIVERY
  // ═══════════════════════════════════════
  Widget _buildStep3PaymentDelivery() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Payment & Delivery',
            'How will customer pay?',
            Iconsax.truck,
          ),

          Gap(20.h),

          // Payment Type
          _buildLabel('Payment Type *'),
          Gap(10.h),

          ...PaymentType.values.map(
            (type) => GestureDetector(
              onTap: () =>
                  setState(() => _selectedPayment = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _selectedPayment == type
                      ? AppColors.traderPrimary
                          .withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _selectedPayment == type
                        ? AppColors.traderPrimary
                        : AppColors.border,
                    width: _selectedPayment == type ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedPayment == type
                              ? AppColors.traderPrimary
                              : AppColors.border,
                          width: 2,
                        ),
                        color: _selectedPayment == type
                            ? AppColors.traderPrimary
                            : Colors.transparent,
                      ),
                      child: _selectedPayment == type
                          ? Icon(
                              Icons.check_rounded,
                              size: 12.sp,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    Gap(12.w),
                    Text(
                      _getPaymentLabel(type),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            _selectedPayment == type
                                ? FontWeight.w700
                                : FontWeight.w400,
                        color: _selectedPayment == type
                            ? AppColors.traderPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Credit days (if credit selected)
          if (_selectedPayment == PaymentType.credit) ...[
            Gap(4.h),
            _buildLabel('Credit Days'),
            Gap(8.h),
            TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (v) =>
                  setState(() => _creditDays = int.tryParse(v)),
              decoration: InputDecoration(
                hintText: 'e.g. 30 days',
                prefixIcon: Icon(
                  Iconsax.calendar,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
                suffixText: 'days',
              ),
            ),
          ],

          Gap(16.h),

          // Delivery Date
          _buildLabel('Expected Delivery Date'),
          Gap(8.h),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now()
                    .add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now()
                    .add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.traderPrimary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (date != null) {
                setState(() => _deliveryDate = date);
              }
            },
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    size: 20.sp,
                    color: AppColors.textHint,
                  ),
                  Gap(12.w),
                  Text(
                    _deliveryDate != null
                        ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                        : 'Select delivery date (optional)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _deliveryDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Gap(16.h),

          // Delivery Location
          _buildLabel('Delivery Location'),
          Gap(8.h),
          TextFormField(
            controller: _deliveryLocationController,
            decoration: InputDecoration(
              hintText: 'Where to deliver? (optional)',
              prefixIcon: Icon(
                Iconsax.location,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
          ),

          Gap(16.h),

          // Additional Note
          _buildLabel('Additional Note'),
          Gap(4.h),
          Text(
            'Any special instructions for admin',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
          Gap(8.h),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g. Customer will pay full cash. Need quick delivery...',
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

          Gap(20.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM BUTTONS
  // ═══════════════════════════════════════
  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.border,
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) Gap(12.w),

          Expanded(
            flex: 2,
            child: CustomButton(
              label: _currentStep == 2
                  ? 'Submit Requirement'
                  : 'Continue',
              isLoading: _isLoading,
              gradient: AppColors.traderGradient,
              prefixIcon: _currentStep == 2
                  ? Iconsax.send_1
                  : Icons.arrow_forward_rounded,
              onPressed: () {
                if (_currentStep < 2) {
                  _pageController.nextPage(
                    duration:
                        const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _submit();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════
  Widget _stepHeader(
      String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            gradient: AppColors.traderGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 22.sp, color: AppColors.white),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
}
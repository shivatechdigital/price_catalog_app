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
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/order_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class TraderSubmitOrderScreen extends ConsumerStatefulWidget {
  const TraderSubmitOrderScreen({super.key});

  @override
  ConsumerState<TraderSubmitOrderScreen> createState() =>
      _TraderSubmitOrderScreenState();
}

class _TraderSubmitOrderScreenState
    extends ConsumerState<TraderSubmitOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // ─── Customer Controllers ────────────────────────────────
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerBusinessCtrl = TextEditingController();
  final _customerCityCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();

  // ─── Payment ─────────────────────────────────────────────
  PaymentType _paymentType = PaymentType.fullCash;
  int? _creditDays;
  DateTime? _deliveryDate;
  final _deliveryLocationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // ─── Per-item price/qty editors ─────────────────────────
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _demandPriceControllers = {};
  final Map<String, TextEditingController> _offerPriceControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final items = ref.read(selectedOrderItemsProvider);
    for (final item in items) {
      _qtyControllers[item.itemId] = TextEditingController(
        text: item.quantity.toStringAsFixed(0),
      );
      _demandPriceControllers[item.itemId] =
          TextEditingController(
        text: item.customerDemandedPrice.toStringAsFixed(0),
      );
      _offerPriceControllers[item.itemId] =
          TextEditingController(
        text: item.traderOfferedPrice.toStringAsFixed(0),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerBusinessCtrl.dispose();
    _customerCityCtrl.dispose();
    _customerAddressCtrl.dispose();
    _deliveryLocationCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _qtyControllers.values) c.dispose();
    for (final c in _demandPriceControllers.values) c.dispose();
    for (final c in _offerPriceControllers.values) c.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // SUBMIT ORDER
  // ═══════════════════════════════════════
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final currentUser = ref.read(currentUserProvider);
    final originalItems = ref.read(selectedOrderItemsProvider);

    // Build updated items with qty/price from controllers
    final updatedItems = originalItems.map((item) {
      final qty = double.tryParse(
            _qtyControllers[item.itemId]?.text ?? '1',
          ) ??
          item.quantity;
      final demandPrice = double.tryParse(
            _demandPriceControllers[item.itemId]?.text ?? '0',
          ) ??
          item.customerDemandedPrice;
      final offerPrice = double.tryParse(
            _offerPriceControllers[item.itemId]?.text ?? '0',
          ) ??
          item.traderOfferedPrice;

      return OrderItemModel(
        itemId: item.itemId,
        productId: item.productId,
        productName: item.productName,
        productCode: item.productCode,
        productImage: item.productImage,
        categoryName: item.categoryName,
        quantity: qty,
        unit: item.unit,
        productCurrentPrice: item.productCurrentPrice,
        customerDemandedPrice: demandPrice,
        traderOfferedPrice: offerPrice,
        status: OrderItemStatus.pending,
      );
    }).toList();

    try {
      await ref.read(orderRepositoryProvider).submitOrder(
            traderId: currentUser?.uid ?? '',
            traderName: currentUser?.name ?? '',
            traderBusinessName:
                currentUser?.businessName ?? '',
            traderPhone: currentUser?.phone ?? '',
            customerName: _customerNameCtrl.text.trim(),
            customerPhone: _customerPhoneCtrl.text.trim(),
            customerBusinessName:
                _customerBusinessCtrl.text.trim(),
            customerCity: _customerCityCtrl.text.trim(),
            customerAddress:
                _customerAddressCtrl.text.trim().isEmpty
                    ? null
                    : _customerAddressCtrl.text.trim(),
            paymentType: _paymentType,
            creditDays: _creditDays,
            deliveryDate: _deliveryDate,
            deliveryLocation:
                _deliveryLocationCtrl.text.trim().isEmpty
                    ? null
                    : _deliveryLocationCtrl.text.trim(),
            traderNote: _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
            items: updatedItems,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Clear selection
      ref.read(selectedOrderItemsProvider.notifier).state = [];

      // Pop all screens back to catalog
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );

      CustomSnackbar.showSuccess(
        context,
        '✅ Order submitted! ${updatedItems.length} products sent for approval.',
      );
    } catch (e) {
      debugPrint('Failed to submit order: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.showError(
        context,
        'Failed to submit order. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(selectedOrderItemsProvider);

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
          'Submit Order',
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
            // ─── STEP INDICATOR ──────────────────────────
            _buildStepIndicator(),

            // ─── PAGE VIEW ───────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) =>
                    setState(() => _currentStep = i),
                children: [
                  _buildStep1ProductPrices(items),
                  _buildStep2CustomerDetails(),
                  _buildStep3PaymentDelivery(),
                  _buildStep4Review(items),
                ],
              ),
            ),

            // ─── BOTTOM BUTTONS ──────────────────────────
            _buildBottomButtons(items),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP INDICATOR
  // ═══════════════════════════════════════
  Widget _buildStepIndicator() {
    final steps = ['Products', 'Customer', 'Payment', 'Review'];

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.traderPrimary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isActive
                              ? AppColors.traderPrimary
                              : isDone
                                  ? AppColors.approved
                                  : AppColors.textHint,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) Gap(4.w),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 1: PRODUCT PRICES & QTY
  // ═══════════════════════════════════════
  Widget _buildStep1ProductPrices(List<OrderItemModel> items) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _stepHeader(
            '${items.length} Products Selected',
            'Set quantity & price for each product',
            Iconsax.box,
          ),

          Gap(16.h),

          // Per item cards
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _ProductPriceCard(
              item: item,
              index: index,
              qtyController: _qtyControllers[item.itemId]!,
              demandController:
                  _demandPriceControllers[item.itemId]!,
              offerController:
                  _offerPriceControllers[item.itemId]!,
              onRemove: () {
                final current =
                    ref.read(selectedOrderItemsProvider);
                ref
                    .read(selectedOrderItemsProvider.notifier)
                    .state = current
                    .where((i) => i.itemId != item.itemId)
                    .toList();
                _qtyControllers[item.itemId]?.dispose();
                _demandPriceControllers[item.itemId]
                    ?.dispose();
                _offerPriceControllers[item.itemId]?.dispose();
                _qtyControllers.remove(item.itemId);
                _demandPriceControllers.remove(item.itemId);
                _offerPriceControllers.remove(item.itemId);
              },
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 80))
                .slideY(begin: 0.1, end: 0);
          }),

          Gap(20.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 2: CUSTOMER DETAILS
  // ═══════════════════════════════════════
  Widget _buildStep2CustomerDetails() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Customer Details',
            'Who is buying these products?',
            Iconsax.shop,
          ),

          Gap(20.h),

          _buildLabel('Customer / Shopkeeper Name *'),
          Gap(8.h),
          TextFormField(
            controller: _customerNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Mahesh Hardware Store',
              prefixIcon: Icon(
                Iconsax.user,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Required'
                : null,
          ),

          Gap(14.h),

          _buildLabel('Phone Number *'),
          Gap(8.h),
          TextFormField(
            controller: _customerPhoneCtrl,
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
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 10) return 'Enter valid number';
              return null;
            },
          ),

          Gap(14.h),

          _buildLabel('Business Name *'),
          Gap(8.h),
          TextFormField(
            controller: _customerBusinessCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Mahesh Hardware & Traders',
              prefixIcon: Icon(
                Iconsax.building,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Required'
                : null,
          ),

          Gap(14.h),

          _buildLabel('City *'),
          Gap(8.h),
          TextFormField(
            controller: _customerCityCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Pune',
              prefixIcon: Icon(
                Iconsax.location,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Required'
                : null,
          ),

          Gap(14.h),

          _buildLabel('Address (Optional)'),
          Gap(8.h),
          TextFormField(
            controller: _customerAddressCtrl,
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

          Gap(24.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 3: PAYMENT & DELIVERY
  // ═══════════════════════════════════════
  Widget _buildStep3PaymentDelivery() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Payment & Delivery',
            'How will the customer pay?',
            Iconsax.truck,
          ),

          Gap(20.h),

          _buildLabel('Payment Type *'),
          Gap(10.h),

          ...PaymentType.values.map(
            (type) => GestureDetector(
              onTap: () =>
                  setState(() => _paymentType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _paymentType == type
                      ? AppColors.traderPrimary
                          .withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _paymentType == type
                        ? AppColors.traderPrimary
                        : AppColors.border,
                    width: _paymentType == type ? 1.5 : 1,
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
                          color: _paymentType == type
                              ? AppColors.traderPrimary
                              : AppColors.border,
                          width: 2,
                        ),
                        color: _paymentType == type
                            ? AppColors.traderPrimary
                            : Colors.transparent,
                      ),
                      child: _paymentType == type
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
                        fontWeight: _paymentType == type
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: _paymentType == type
                            ? AppColors.traderPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_paymentType == PaymentType.credit) ...[
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
                hintText: 'e.g. 30',
                prefixIcon: Icon(
                  Iconsax.calendar,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
                suffixText: 'days',
              ),
            ),
            Gap(14.h),
          ],

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
                        : 'Select date (optional)',
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

          Gap(14.h),

          _buildLabel('Delivery Location'),
          Gap(8.h),
          TextFormField(
            controller: _deliveryLocationCtrl,
            decoration: InputDecoration(
              hintText: 'Where to deliver? (optional)',
              prefixIcon: Icon(
                Iconsax.location,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
          ),

          Gap(14.h),

          _buildLabel('Additional Note'),
          Gap(8.h),
          TextFormField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Special instructions for admin...',
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

          Gap(24.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 4: ORDER REVIEW
  // ═══════════════════════════════════════
  Widget _buildStep4Review(List<OrderItemModel> items) {
    // Calculate total from controllers
    double totalValue = 0;
    for (final item in items) {
      final qty = double.tryParse(
            _qtyControllers[item.itemId]?.text ?? '0',
          ) ??
          0;
      final price = double.tryParse(
            _demandPriceControllers[item.itemId]?.text ?? '0',
          ) ??
          0;
      totalValue += qty * price;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Review Order',
            'Verify before submitting',
            Iconsax.document_text,
          ),

          Gap(16.h),

          // ─── Products Summary ──────────────────────────
          Container(
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
                    Icon(
                      Iconsax.box,
                      size: 16.sp,
                      color: AppColors.traderPrimary,
                    ),
                    Gap(8.w),
                    Text(
                      '${items.length} Products',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                ...items.map((item) {
                  final qty = _qtyControllers[item.itemId]
                          ?.text ??
                      '1';
                  final price = _demandPriceControllers[
                              item.itemId]
                          ?.text ??
                      '0';
                  final itemTotal =
                      (double.tryParse(qty) ?? 0) *
                          (double.tryParse(price) ?? 0);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: AppColors.traderPrimary
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(8.r),
                          ),
                          child: item.productImage != null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8.r),
                                  child: Image.network(
                                    item.productImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Icon(
                                      Iconsax.box,
                                      size: 16.sp,
                                      color:
                                          AppColors.traderPrimary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Iconsax.box,
                                  size: 16.sp,
                                  color: AppColors.traderPrimary,
                                ),
                        ),
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
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$qty ${item.unit} × ₹$price',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${itemTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Value',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${totalValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.traderPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Gap(12.h),

          // ─── Customer Summary ──────────────────────────
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow(
                  Iconsax.user,
                  'Customer',
                  _customerNameCtrl.text,
                ),
                Gap(8.h),
                _reviewRow(
                  Iconsax.building,
                  'Business',
                  _customerBusinessCtrl.text,
                ),
                Gap(8.h),
                _reviewRow(
                  Iconsax.call,
                  'Phone',
                  '+91 ${_customerPhoneCtrl.text}',
                ),
                Gap(8.h),
                _reviewRow(
                  Iconsax.location,
                  'City',
                  _customerCityCtrl.text,
                ),
              ],
            ),
          ),

          Gap(12.h),

          // ─── Payment Summary ───────────────────────────
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                _reviewRow(
                  Iconsax.money,
                  'Payment',
                  _getPaymentLabel(_paymentType),
                ),
                if (_deliveryDate != null) ...[
                  Gap(8.h),
                  _reviewRow(
                    Iconsax.truck,
                    'Delivery',
                    '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}',
                  ),
                ],
                if (_deliveryLocationCtrl.text.isNotEmpty) ...[
                  Gap(8.h),
                  _reviewRow(
                    Iconsax.location,
                    'Location',
                    _deliveryLocationCtrl.text,
                  ),
                ],
                if (_noteCtrl.text.isNotEmpty) ...[
                  Gap(8.h),
                  _reviewRow(
                    Iconsax.note_text,
                    'Note',
                    _noteCtrl.text,
                  ),
                ],
              ],
            ),
          ),

          Gap(24.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM BUTTONS
  // ═══════════════════════════════════════
  Widget _buildBottomButtons(List<OrderItemModel> items) {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
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
                  padding: EdgeInsets.symmetric(vertical: 14.h),
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
              label: isLastStep
                  ? 'Submit Order'
                  : 'Continue',
              isLoading: _isLoading,
              gradient: AppColors.traderGradient,
              prefixIcon: isLastStep
                  ? Iconsax.send_1
                  : Icons.arrow_forward_rounded,
              onPressed: items.isEmpty
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        // Validate current step
                        if (_currentStep == 0) {
                          // Check quantities
                          bool valid = true;
                          for (final item in items) {
                            final qty = double.tryParse(
                              _qtyControllers[item.itemId]
                                      ?.text ??
                                  '0',
                            );
                            if (qty == null || qty <= 0) {
                              valid = false;
                              break;
                            }
                          }
                          if (!valid) {
                            CustomSnackbar.showWarning(
                              context,
                              'Please enter valid quantity for all products',
                            );
                            return;
                          }
                        }
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

  // ─── Helper Widgets ──────────────────────────────────────
  Widget _stepHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
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
                  fontSize: 17.sp,
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
    ).animate().fadeIn().slideX(begin: -0.1);
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

  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textHint),
        Gap(8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textHint,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => '💵 Full Cash',
      PaymentType.partialPayment => '💳 Partial Payment',
      PaymentType.credit => '📋 Credit',
    };
  }
}

// ═══════════════════════════════════════
// PRODUCT PRICE CARD (Per Item in Step 1)
// ═══════════════════════════════════════
class _ProductPriceCard extends StatelessWidget {
  final OrderItemModel item;
  final int index;
  final TextEditingController qtyController;
  final TextEditingController demandController;
  final TextEditingController offerController;
  final VoidCallback onRemove;

  const _ProductPriceCard({
    required this.item,
    required this.index,
    required this.qtyController,
    required this.demandController,
    required this.offerController,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
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
          // ─── Product Header ──────────────────────────────
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.traderPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.traderPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                Gap(10.w),
                // Product Image
                if (item.productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      item.productImage!,
                      width: 36.w,
                      height: 36.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36.w,
                        height: 36.w,
                        color: AppColors.background,
                        child: Icon(
                          Iconsax.box,
                          size: 18.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Iconsax.box,
                      size: 18.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                Gap(10.w),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        item.productCode,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: AppColors.rejectedLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14.sp,
                      color: AppColors.rejected,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Fields ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                // Current price info
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 12.sp,
                        color: AppColors.textHint,
                      ),
                      Gap(4.w),
                      Text(
                        'Current price: ₹${item.productCurrentPrice.toStringAsFixed(0)}/${item.unit}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Gap(12.h),

                // Quantity
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity *',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Gap(6.h),
                          TextFormField(
                            controller: qtyController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText:
                                  item.unit.toUpperCase(),
                              suffixStyle: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(v) == null ||
                                  double.parse(v) <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Gap(10.h),

                // Demanded & Offered Price
                Row(
                  children: [
                    // Customer Demanded
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Demands (₹) *',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.pending,
                            ),
                          ),
                          Gap(6.h),
                          TextFormField(
                            controller: demandController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pending,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.pending,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    Gap(10.w),

                    // Trader Offered
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You Offer (₹) *',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adminPrimary,
                            ),
                          ),
                          Gap(6.h),
                          TextFormField(
                            controller: offerController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adminPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.adminPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
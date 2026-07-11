// TODO Implement this library.import 'dart:io';
// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/category_model.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product; // null = add, not null = edit

  const AddProductScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  ConsumerState<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _brandController = TextEditingController();
  final _descController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _dealerPriceController = TextEditingController();
  final _minPriceController = TextEditingController();

  // State
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  String _selectedUnit = 'ton';
  ProductAvailability _availability = ProductAvailability.inStock;
  List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;

  final List<String> _units = [
    'ton', 'kg', 'gram', 'meter', 'feet',
    'inch', 'piece', 'box', 'bag', 'liter',
    'bundle', 'roll', 'sheet',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final p = widget.product!;
    _nameController.text = p.name;
    _codeController.text = p.productCode;
    _brandController.text = p.brand;
    _descController.text = p.description;
    _purchasePriceController.text =
        p.currentPrice.purchasePrice.toStringAsFixed(0);
    _sellingPriceController.text =
        p.currentPrice.sellingPrice.toStringAsFixed(0);
    _dealerPriceController.text =
        p.currentPrice.dealerPrice.toStringAsFixed(0);
    _minPriceController.text =
        (p.currentPrice.minAcceptedPrice ?? 0).toStringAsFixed(0);
    _selectedCategoryId = p.categoryId;
    _selectedCategoryName = p.categoryName;
    _selectedSubCategoryId = p.subCategoryId;
    _selectedSubCategoryName = p.subCategoryName;
    _selectedUnit = p.unit;
    _availability = p.availability;
    _existingImages = List.from(p.images);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _brandController.dispose();
    _descController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _dealerPriceController.dispose();
    _minPriceController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // PICK IMAGES
  // ═══════════════════════════════════════
  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picker = ImagePicker();
        final images = await picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (images.isNotEmpty) {
          setState(() {
            _newImages.addAll(
              images.map((e) => File(e.path)).toList(),
            );
          });
        }
      } else {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (image != null) {
          setState(() {
            _newImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to pick image');
      }
    }
  }

  // ═══════════════════════════════════════
  // SHOW IMAGE SOURCE PICKER
  // ═══════════════════════════════════════
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            Gap(16.h),
            Text(
              'Add Product Image',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(20.h),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceOption(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.camera);
                    },
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: _ImageSourceOption(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SAVE PRODUCT
  // ═══════════════════════════════════════
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      CustomSnackbar.showWarning(
        context,
        'Please select a category',
      );
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final currentUser = ref.read(currentUserProvider);
      final repo = ref.read(productRepositoryProvider);

      final price = PriceModel(
        purchasePrice:
            double.parse(_purchasePriceController.text),
        sellingPrice:
            double.parse(_sellingPriceController.text),
        dealerPrice:
            double.parse(_dealerPriceController.text),
        minAcceptedPrice: _minPriceController.text.isNotEmpty
            ? double.tryParse(_minPriceController.text)
            : null,
        updatedAt: DateTime.now(),
        updatedBy: currentUser?.uid ?? '',
      );

      if (widget.isEditing) {
        // Update existing product
        await repo.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text,
          productCode: _codeController.text,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName!,
          subCategoryId: _selectedSubCategoryId,
          subCategoryName: _selectedSubCategoryName,
          brand: _brandController.text,
          description: _descController.text,
          unit: _selectedUnit,
          availability: _availability,
        );

        // Update price if changed
        final oldPrice = widget.product!.currentPrice;
        if (price.sellingPrice != oldPrice.sellingPrice ||
            price.dealerPrice != oldPrice.dealerPrice ||
            price.purchasePrice != oldPrice.purchasePrice) {
          await repo.updatePrice(
            productId: widget.product!.id,
            productName: _nameController.text,
            newPrice: price,
            oldPrice: oldPrice,
            updatedBy: currentUser?.uid ?? '',
            updatedByName: currentUser?.name ?? '',
            changeReason: 'Product edit update',
          );
        }
      } else {
        // Add new product
        final newProduct = await repo.addProduct(
          name: _nameController.text,
          productCode: _codeController.text,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName!,
          subCategoryId: _selectedSubCategoryId,
          subCategoryName: _selectedSubCategoryName,
          brand: _brandController.text,
          description: _descController.text,
          unit: _selectedUnit,
          price: price,
          createdBy: currentUser?.uid ?? '',
        );

        // Upload new images
        for (int i = 0; i < _newImages.length; i++) {
          await repo.uploadProductImage(
            productId: newProduct.id,
            imageFile: _newImages[i],
            index: i,
          );
        }

        // Update category product count
        ref
            .read(categoryRepositoryProvider)
            .incrementProductCount(_selectedCategoryId!);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pop(context);
      CustomSnackbar.showSuccess(
        context,
        widget.isEditing
            ? 'Product updated successfully!'
            : 'Product added successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.showError(
        context,
        'Failed to save product. Please try again.',
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
          widget.isEditing ? 'Edit Product' : 'Add New Product',
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
            // Step Indicator
            _buildStepIndicator(),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) =>
                    setState(() => _currentStep = i),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Pricing(),
                  _buildStep3Images(),
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
  // STEP INDICATOR
  // ═══════════════════════════════════════
  Widget _buildStepIndicator() {
    final steps = ['Basic Info', 'Pricing', 'Images'];
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 12.h,
      ),
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
                        width: double.infinity,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.adminPrimary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      Gap(6.h),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.adminPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) Gap(8.w),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STEP 1 - BASIC INFO
  // ═══════════════════════════════════════
  Widget _buildStep1BasicInfo() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          _buildFieldLabel('Product Name *'),
          Gap(8.h),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Iron Sariya 8mm',
              prefixIcon: Icon(
                Iconsax.box,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Product name is required'
                : null,
          ),

          Gap(16.h),

          // Product Code
          _buildFieldLabel('Product Code *'),
          Gap(8.h),
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. IS-8MM-001',
              prefixIcon: Icon(
                Iconsax.barcode,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Product code is required'
                : null,
          ),

          Gap(16.h),

          // Brand
          _buildFieldLabel('Brand Name *'),
          Gap(8.h),
          TextFormField(
            controller: _brandController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. TATA Steel',
              prefixIcon: Icon(
                Iconsax.medal,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Brand name is required'
                : null,
          ),

          Gap(16.h),

          // Category Dropdown
          _buildFieldLabel('Category *'),
          Gap(8.h),
          categoriesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) =>
                const Text('Failed to load categories'),
            data: (categories) =>
                _buildCategoryDropdown(categories),
          ),

          Gap(16.h),

          // Sub Category (if category selected)
          if (_selectedCategoryId != null)
            _buildSubCategorySection(
              categoriesAsync.asData?.value ?? [],
            ),

          Gap(16.h),

          // Unit
          _buildFieldLabel('Unit *'),
          Gap(8.h),
          DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Iconsax.weight,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            items: _units
                .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(
                        u.toUpperCase(),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedUnit = v ?? 'ton'),
          ),

          Gap(16.h),

          // Availability
          _buildFieldLabel('Availability'),
          Gap(8.h),
          _buildAvailabilitySelector(),

          Gap(16.h),

          // Description
          _buildFieldLabel('Description'),
          Gap(8.h),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Product description, specifications...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60.h),
                child: Icon(
                  Iconsax.document_text,
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
  // CATEGORY DROPDOWN
  // ═══════════════════════════════════════
  Widget _buildCategoryDropdown(List<CategoryModel> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      hint: Text(
        'Select Category',
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textHint,
        ),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Iconsax.category,
          size: 20.sp,
          color: AppColors.textHint,
        ),
      ),
      items: categories
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Text(c.icon),
                    Gap(8.w),
                    Text(
                      c.name,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) {
        final category = categories.firstWhere((c) => c.id == v);
        setState(() {
          _selectedCategoryId = v;
          _selectedCategoryName = category.name;
          _selectedSubCategoryId = null;
          _selectedSubCategoryName = null;
        });
      },
      validator: (v) =>
          v == null ? 'Please select a category' : null,
    );
  }

  // ═══════════════════════════════════════
  // SUB CATEGORY SECTION
  // ═══════════════════════════════════════
  Widget _buildSubCategorySection(List<CategoryModel> categories) {
    final selectedCat = categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    if (selectedCat == null ||
        selectedCat.subCategories.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Sub Category'),
        Gap(8.h),
        DropdownButtonFormField<String>(
          value: _selectedSubCategoryId,
          hint: Text(
            'Select Sub Category (Optional)',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textHint,
            ),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Iconsax.category_2,
              size: 20.sp,
              color: AppColors.textHint,
            ),
          ),
          items: selectedCat.subCategories
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Row(
                      children: [
                        Text(s.icon),
                        Gap(8.w),
                        Text(
                          s.name,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            final sub = selectedCat.subCategories
                .firstWhere((s) => s.id == v);
            setState(() {
              _selectedSubCategoryId = v;
              _selectedSubCategoryName = sub.name;
            });
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // AVAILABILITY SELECTOR
  // ═══════════════════════════════════════
  Widget _buildAvailabilitySelector() {
    return Row(
      children: [
        _AvailabilityChip(
          label: '✅ In Stock',
          isSelected: _availability == ProductAvailability.inStock,
          color: AppColors.approved,
          onTap: () => setState(
            () => _availability = ProductAvailability.inStock,
          ),
        ),
        Gap(8.w),
        _AvailabilityChip(
          label: '⚠️ Limited',
          isSelected:
              _availability == ProductAvailability.limitedStock,
          color: AppColors.counter,
          onTap: () => setState(
            () => _availability = ProductAvailability.limitedStock,
          ),
        ),
        Gap(8.w),
        _AvailabilityChip(
          label: '❌ Out',
          isSelected:
              _availability == ProductAvailability.outOfStock,
          color: AppColors.rejected,
          onTap: () => setState(
            () => _availability = ProductAvailability.outOfStock,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // STEP 2 - PRICING
  // ═══════════════════════════════════════
  Widget _buildStep2Pricing() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Box
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.adminPrimary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 18.sp,
                  color: AppColors.adminPrimary,
                ),
                Gap(10.w),
                Expanded(
                  child: Text(
                    'Purchase price is only visible to admin. '
                    'Traders see dealer and selling price.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.adminPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Gap(20.h),

          // Purchase Price
          _buildFieldLabel('Purchase Price (₹) *'),
          Gap(8.h),
          _buildPriceField(
            controller: _purchasePriceController,
            hint: 'Admin cost price',
            icon: Iconsax.wallet,
            color: AppColors.rejected,
          ),

          Gap(16.h),

          // Selling Price
          _buildFieldLabel('Selling Price (₹) *'),
          Gap(8.h),
          _buildPriceField(
            controller: _sellingPriceController,
            hint: 'Official selling price',
            icon: Iconsax.money,
            color: AppColors.textPrimary,
          ),

          Gap(16.h),

          // Dealer Price
          _buildFieldLabel('Dealer Price (₹) *'),
          Gap(8.h),
          _buildPriceField(
            controller: _dealerPriceController,
            hint: 'Price for traders/dealers',
            icon: Iconsax.people,
            color: AppColors.adminPrimary,
          ),

          Gap(16.h),

          // Minimum Accepted Price
          _buildFieldLabel('Minimum Accepted Price (₹)'),
          Gap(4.h),
          Text(
            'Requirements below this price will need special approval',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textHint,
            ),
          ),
          Gap(8.h),
          _buildPriceField(
            controller: _minPriceController,
            hint: 'Optional - minimum deal price',
            icon: Iconsax.arrow_down,
            color: AppColors.counter,
            isRequired: false,
          ),

          Gap(20.h),

          // Price Preview Card
          _buildPricePreviewCard(),

          Gap(20.h),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20.sp, color: color),
        prefixText: '₹ ',
        prefixStyle: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: isRequired
          ? (v) {
              if (v == null || v.isEmpty) {
                return 'Price is required';
              }
              final price = double.tryParse(v);
              if (price == null || price <= 0) {
                return 'Enter valid price';
              }
              return null;
            }
          : null,
    );
  }

  // ═══════════════════════════════════════
  // PRICE PREVIEW CARD
  // ═══════════════════════════════════════
  Widget _buildPricePreviewCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.adminGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPreviewItem(
                'Purchase',
                _purchasePriceController.text.isEmpty
                    ? '₹0'
                    : '₹${_purchasePriceController.text}',
              ),
              _buildPreviewItem(
                'Selling',
                _sellingPriceController.text.isEmpty
                    ? '₹0'
                    : '₹${_sellingPriceController.text}',
              ),
              _buildPreviewItem(
                'Dealer',
                _dealerPriceController.text.isEmpty
                    ? '₹0'
                    : '₹${_dealerPriceController.text}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.white.withOpacity(0.7),
          ),
        ),
        Gap(4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // STEP 3 - IMAGES
  // ═══════════════════════════════════════
  Widget _buildStep3Images() {
    final totalImages = _existingImages.length + _newImages.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Product Images'),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$totalImages / 10',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          Gap(8.h),

          Text(
            'Add up to 10 images. First image will be the main photo.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),

          Gap(16.h),

          // Image Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemCount: totalImages < 10
                ? totalImages + 1
                : totalImages,
            itemBuilder: (context, index) {
              // Add button
              if (index == totalImages && totalImages < 10) {
                return _buildAddImageBtn();
              }

              // Existing images
              if (index < _existingImages.length) {
                return _buildExistingImageCard(
                  _existingImages[index],
                  index,
                );
              }

              // New images
              final newIndex = index - _existingImages.length;
              return _buildNewImageCard(
                _newImages[newIndex],
                newIndex,
              );
            },
          ),

          Gap(20.h),

          // Tips
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildTip('📸 Use good lighting for clear photos'),
                Gap(6.h),
                _buildTip('🎯 Show product from multiple angles'),
                Gap(6.h),
                _buildTip(
                    '📏 Max 5MB per image, JPG/PNG format'),
              ],
            ),
          ),

          Gap(20.h),
        ],
      ),
    );
  }

  Widget _buildAddImageBtn() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.adminPrimary.withOpacity(0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.add_circle,
              size: 28.sp,
              color: AppColors.adminPrimary,
            ),
            Gap(6.h),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImageCard(String url, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.adminPrimary,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Main',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _existingImages.removeAt(index);
              });
            },
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: AppColors.rejected,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 12.sp,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageCard(File file, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.counter,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _newImages.removeAt(index);
              });
            },
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: AppColors.rejected,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 12.sp,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
          // Back button
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
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

          // Next/Save button
          Expanded(
            flex: 2,
            child: CustomButton(
              label: _currentStep == 2
                  ? (widget.isEditing
                      ? 'Update Product'
                      : 'Save Product')
                  : 'Continue',
              isLoading: _isLoading,
              gradient: AppColors.adminGradient,
              prefixIcon: _currentStep == 2
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: () {
                if (_currentStep < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _save();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ═══════════════════════════════════════
// AVAILABILITY CHIP
// ═══════════════════════════════════════
class _AvailabilityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AvailabilityChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected
                ? FontWeight.w700
                : FontWeight.w400,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// IMAGE SOURCE OPTION
// ═══════════════════════════════════════
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                gradient: AppColors.adminGradient,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                icon,
                size: 24.sp,
                color: AppColors.white,
              ),
            ),
            Gap(10.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
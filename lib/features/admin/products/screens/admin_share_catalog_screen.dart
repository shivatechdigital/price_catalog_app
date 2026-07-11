import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/core/services/excel_service.dart';
import 'package:price_catalog_app/core/services/pdf_service.dart';
import 'package:price_catalog_app/core/services/share_service.dart';
import 'package:price_catalog_app/data/models/app_settings_model.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class AdminShareCatalogScreen extends ConsumerStatefulWidget {
  const AdminShareCatalogScreen({super.key});

  @override
  ConsumerState<AdminShareCatalogScreen> createState() =>
      _AdminShareCatalogScreenState();
}

class _AdminShareCatalogScreenState
    extends ConsumerState<AdminShareCatalogScreen> {
  final Set<String> _selectedProductIds = {};
  bool _showPrices = true;
  bool _isGeneratingPdf = false;
  bool _isGeneratingExcel = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

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
          'Share Catalog',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Select All
          TextButton(
            onPressed: () {
             final products = productsAsync.value ?? [];
              setState(() {
                if (_selectedProductIds.length ==
                    products.length) {
                  _selectedProductIds.clear();
                } else {
                  _selectedProductIds.clear();
                  _selectedProductIds.addAll(
                    products.map((p) => p.id),
                  );
                }
              });
            },
            child: Text(
              'Select All',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── OPTIONS BAR ────────────────────────
          Container(
            color: AppColors.white,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  Iconsax.money,
                  size: 18.sp,
                  color: AppColors.textSecondary,
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    'Include prices in catalog',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _showPrices,
                  onChanged: (v) =>
                      setState(() => _showPrices = v),
                  activeColor: AppColors.adminPrimary,
                ),
              ],
            ),
          ),

          // ─── SELECTION INFO ──────────────────────
          Container(
            color: AppColors.adminPrimary.withOpacity(0.06),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.tick_square,
                  size: 16.sp,
                  color: AppColors.adminPrimary,
                ),
                Gap(8.w),
                Text(
                  '${_selectedProductIds.length} products selected',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ─── PRODUCT LIST ────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load products'),
              ),
              data: (products) => ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  12.h,
                  16.w,
                  100.h,
                ),
                itemCount: products.length,
                separatorBuilder: (_, __) => Gap(8.h),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isSelected = _selectedProductIds
                      .contains(product.id);

                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedProductIds
                            .remove(product.id);
                      } else {
                        _selectedProductIds.add(product.id);
                      }
                    }),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.adminPrimary
                                .withOpacity(0.06)
                            : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.adminPrimary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.adminPrimary
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.adminPrimary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 14.sp,
                                    color: AppColors.white,
                                  )
                                : null,
                          ),

                          Gap(12.w),

                          // Image
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius:
                                  BorderRadius.circular(10.r),
                            ),
                            child: product.primaryImage
                                    .isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            10.r),
                                    child: Image.network(
                                      product.primaryImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                        Iconsax.box,
                                        size: 20.sp,
                                        color:
                                            AppColors.textHint,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Iconsax.box,
                                    size: 20.sp,
                                    color: AppColors.textHint,
                                  ),
                          ),

                          Gap(12.w),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  product.categoryName,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Price
                          Text(
                            '₹${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adminPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(
                          milliseconds: index * 40,
                        ),
                      );
                },
              ),
            ),
          ),

          // ─── ACTION BUTTONS ──────────────────────
          productsAsync.when(
            data: (products) => _buildBottomActions(products),
            loading: () => _buildBottomActions([]),
            error: (_, __) => _buildBottomActions([]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(List<ProductModel> allProducts) {
    final selectedProducts = allProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PDF Button
          CustomButton(
            label: _isGeneratingPdf
                ? 'Generating PDF...'
                : 'Generate & Share PDF',
            isLoading: _isGeneratingPdf,
            gradient: AppColors.adminGradient,
            prefixIcon: Iconsax.document,
            onPressed: selectedProducts.isEmpty
                ? null
                : () => _generatePdf(selectedProducts),
          ),

          Gap(10.h),

          Row(
            children: [
              // Excel Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectedProducts.isEmpty ||
                          _isGeneratingExcel
                      ? null
                      : () => _generateExcel(selectedProducts),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.adminPrimary,
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: _isGeneratingExcel
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.adminPrimary,
                          ),
                        )
                      : Icon(
                          Iconsax.document_text,
                          size: 18.sp,
                          color: AppColors.adminPrimary,
                        ),
                  label: Text(
                    'Excel',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Gap(10.w),

              // WhatsApp Text Share
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectedProducts.isEmpty
                      ? null
                      : () => _shareViaWhatsApp(
                            selectedProducts,
                          ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF25D366),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.message_rounded,
                    size: 18.sp,
                    color: const Color(0xFF25D366),
                  ),
                  label: Text(
                    'WhatsApp',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF25D366),
                      fontWeight: FontWeight.w600,
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

  Future<void> _generatePdf(
      List<ProductModel> products) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final settings = AppSettingsModel.defaults();
      final pdfFile = await PdfService.generateCatalogPdf(
        products: products,
        settings: settings,
        showPrices: _showPrices,
      );

      if (!mounted) return;

      await ShareService.shareFile(
        file: pdfFile,
        subject: 'Product Catalog',
        text: 'Please find our product catalog attached.',
      );
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to generate PDF',
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generateExcel(
      List<ProductModel> products) async {
    setState(() => _isGeneratingExcel = true);
    try {
      final excelFile = await ExcelService.generatePriceListExcel(
        products: products,
        companyName: 'Company Name',
      );

      if (!mounted) return;

      await ShareService.shareFile(
        file: excelFile,
        subject: 'Price List',
        text: 'Please find our price list attached.',
      );
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to generate Excel',
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingExcel = false);
    }
  }

  Future<void> _shareViaWhatsApp(
      List<ProductModel> products) async {
    final text = ShareService.generatePriceListText(
      products: products,
      companyName: 'Company Name',
    );
    await ShareService.shareTextViaWhatsApp(message: text);
  }
}
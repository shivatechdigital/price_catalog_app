import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/providers/product_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

// ═══════════════════════════════════════
// PARSED EXCEL ROW
// ═══════════════════════════════════════
class _ExcelRow {
  final String name;
  final String productCode;
  final String categoryName;
  final String brand;
  final String description;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double dealerPrice;
  final double? minAcceptedPrice;
  final double? stockQuantity;
  bool hasError;
  String? errorMessage;

  _ExcelRow({
    required this.name,
    required this.productCode,
    required this.categoryName,
    required this.brand,
    required this.description,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.dealerPrice,
    this.minAcceptedPrice,
    this.stockQuantity,
    this.hasError = false,
    this.errorMessage,
  });
}

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  List<_ExcelRow> _rows = [];
  bool _isParsing = false;
  bool _isImporting = false;
  int _importedCount = 0;
  int _failedCount = 0;

  // ═══════════════════════════════════════
  // PICK FILE
  // ═══════════════════════════════════════
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      setState(() {
        _isParsing = true;
        _rows = [];
      });

      final bytes = File(path).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final rows = <_ExcelRow>[];
      final sheet = excel.tables.values.first;

      // Skip header row (row index 0)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);

        final name = _cellString(row, 0);
        if (name.isEmpty) continue; // Skip empty rows

        final code = _cellString(row, 1);
        final category = _cellString(row, 2);
        final brand = _cellString(row, 3);
        final desc = _cellString(row, 4);
        final unit = _cellString(row, 5);
        final purchase = _cellDouble(row, 6);
        final selling = _cellDouble(row, 7);
        final dealer = _cellDouble(row, 8);
        final minPrice = _cellDoubleNullable(row, 9);
        final stock = _cellDoubleNullable(row, 10);

        String? error;
        if (name.isEmpty) error = 'Name required';
        else if (code.isEmpty) error = 'Code required';
        else if (category.isEmpty) error = 'Category required';
        else if (brand.isEmpty) error = 'Brand required';
        else if (unit.isEmpty) error = 'Unit required';
        else if (purchase <= 0) error = 'Invalid purchase price';
        else if (selling <= 0) error = 'Invalid selling price';
        else if (dealer <= 0) error = 'Invalid dealer price';

        rows.add(_ExcelRow(
          name: name,
          productCode: code,
          categoryName: category,
          brand: brand,
          description: desc,
          unit: unit,
          purchasePrice: purchase,
          sellingPrice: selling,
          dealerPrice: dealer,
          minAcceptedPrice: minPrice,
          stockQuantity: stock,
          hasError: error != null,
          errorMessage: error,
        ));
      }

      setState(() {
        _rows = rows;
        _isParsing = false;
      });

      if (rows.isEmpty) {
        if (mounted) {
          CustomSnackbar.showWarning(context, 'No data found in file (check header row).');
        }
      }
    } catch (e) {
      setState(() => _isParsing = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to read file. Use .xlsx format.');
      }
    }
  }

  String _cellString(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final v = row[col]?.value;
    if (v == null) return '';
    return v.toString().trim();
  }

  double _cellDouble(List<Data?> row, int col) {
    if (col >= row.length) return 0;
    final v = row[col]?.value;
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  double? _cellDoubleNullable(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final v = row[col]?.value;
    if (v == null || v.toString().trim().isEmpty) return null;
    return double.tryParse(v.toString());
  }

  // ═══════════════════════════════════════
  // IMPORT PRODUCTS
  // ═══════════════════════════════════════
  Future<void> _importProducts() async {
    final validRows = _rows.where((r) => !r.hasError).toList();
    if (validRows.isEmpty) {
      CustomSnackbar.showWarning(context, 'No valid rows to import.');
      return;
    }

    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _failedCount = 0;
    });

    final currentUser = ref.read(currentUserProvider);
    final repo = ref.read(productRepositoryProvider);
    final categoriesAsync = ref.read(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    for (final row in validRows) {
      try {
        // Find or use category name directly (match by name)
        final matchedCat = categories.firstWhere(
          (c) => c.name.toLowerCase() == row.categoryName.toLowerCase(),
          orElse: () => categories.isNotEmpty ? categories.first : throw Exception('No categories'),
        );

        final price = PriceModel(
          purchasePrice: row.purchasePrice,
          sellingPrice: row.sellingPrice,
          dealerPrice: row.dealerPrice,
          minAcceptedPrice: row.minAcceptedPrice,
          updatedAt: DateTime.now(),
          updatedBy: currentUser?.uid ?? '',
        );

        await repo.addProduct(
          name: row.name,
          productCode: row.productCode,
          categoryId: matchedCat.id,
          categoryName: matchedCat.name,
          brand: row.brand,
          description: row.description,
          unit: row.unit,
          price: price,
          createdBy: currentUser?.uid ?? '',
          stockQuantity: row.stockQuantity,
        );

        setState(() => _importedCount++);
      } catch (e) {
        setState(() => _failedCount++);
      }
    }

    setState(() => _isImporting = false);

    if (mounted) {
      if (_importedCount > 0) {
        CustomSnackbar.showSuccess(
          context,
          '$_importedCount product(s) imported successfully!'
          '${_failedCount > 0 ? ' $_failedCount failed.' : ''}',
        );
      } else {
        CustomSnackbar.showError(context, 'Import failed. Check categories exist.');
      }
    }
  }

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final validCount = _rows.where((r) => !r.hasError).length;
    final errorCount = _rows.where((r) => r.hasError).length;

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
          'Import via Excel',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Info Card
                  _buildTemplateCard(),
                  Gap(16.h),

                  // Pick File Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isParsing || _isImporting ? null : _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      icon: _isParsing
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Iconsax.document_upload, size: 20.sp, color: AppColors.white),
                      label: Text(
                        _isParsing ? 'Reading File...' : 'Select Excel File (.xlsx)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  if (_rows.isNotEmpty) ...[
                    Gap(16.h),
                    // Summary
                    Row(
                      children: [
                        _buildSummaryChip('$validCount Valid', AppColors.approved),
                        Gap(8.w),
                        if (errorCount > 0)
                          _buildSummaryChip('$errorCount Errors', AppColors.rejected),
                      ],
                    ),
                    Gap(12.h),
                    // Preview Table
                    _buildPreviewTable(),
                  ],
                ],
              ),
            ),
          ),

          // Import Button
          if (_rows.isNotEmpty && validCount > 0)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.approved,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  icon: _isImporting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.upload_rounded, size: 20.sp, color: AppColors.white),
                  label: Text(
                    _isImporting
                        ? 'Importing... ($_importedCount done)'
                        : 'Import $validCount Product(s)',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTemplateCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.adminPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 18.sp, color: AppColors.adminPrimary),
              Gap(8.w),
              Text(
                'Excel Template Format',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adminPrimary,
                ),
              ),
            ],
          ),
          Gap(10.h),
          _buildColumnInfo('A', 'Product Name *'),
          _buildColumnInfo('B', 'Product Code *'),
          _buildColumnInfo('C', 'Category Name * (must match existing)'),
          _buildColumnInfo('D', 'Brand *'),
          _buildColumnInfo('E', 'Description'),
          _buildColumnInfo('F', 'Unit * (ton/kg/meter/piece...)'),
          _buildColumnInfo('G', 'Purchase Price *'),
          _buildColumnInfo('H', 'Selling Price *'),
          _buildColumnInfo('I', 'Dealer Price *'),
          _buildColumnInfo('J', 'Min Accepted Price (optional)'),
          _buildColumnInfo('K', 'Stock Quantity (optional)'),
          Gap(8.h),
          Text(
            'Row 1 = Header row (will be skipped). Data starts from Row 2.',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnInfo(String col, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Text(
                col,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Text(
              'Preview (${_rows.length} rows)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Gap(8.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                color: row.hasError
                    ? AppColors.rejected.withOpacity(0.05)
                    : Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row number
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: row.hasError
                            ? AppColors.rejected.withOpacity(0.12)
                            : AppColors.adminPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 2}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: row.hasError ? AppColors.rejected : AppColors.adminPrimary,
                          ),
                        ),
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Gap(2.h),
                          Text(
                            '${row.productCode} • ${row.categoryName} • ${row.brand}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Gap(2.h),
                          Text(
                            '₹${row.sellingPrice.toStringAsFixed(0)} selling / ₹${row.purchasePrice.toStringAsFixed(0)} purchase',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.adminPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (row.hasError) ...[
                            Gap(4.h),
                            Text(
                              '⚠ ${row.errorMessage}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.rejected,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      row.hasError ? Icons.close_rounded : Icons.check_circle_rounded,
                      size: 18.sp,
                      color: row.hasError ? AppColors.rejected : AppColors.approved,
                    ),
                  ],
                ),
              );
            },
          ),
          Gap(4.h),
        ],
      ),
    );
  }
}

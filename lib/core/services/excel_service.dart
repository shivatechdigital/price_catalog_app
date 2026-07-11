import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

class ExcelService {
  // ═══════════════════════════════════════
  // GENERATE PRICE LIST EXCEL
  // ═══════════════════════════════════════
  static Future<File> generatePriceListExcel({
    required List<ProductModel> products,
    required String companyName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Price List'];
    excel.delete('Sheet1');

    // ─── STYLES ─────────────────────────────────
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 12,
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#3949AB'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 11,
    );

    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F7FA'),
    );

    final boldStyle = CellStyle(bold: true);

    // ─── TITLE ──────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('H1'),
    );
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('$companyName - Price List');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    sheet.setRowHeight(0, 36);

    // ─── DATE ────────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('H2'),
    );
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue(
      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
    );
    sheet.cell(CellIndex.indexByString('A2')).cellStyle =
        CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      italic: true,
    );

    // ─── EMPTY ROW ───────────────────────────────
    sheet.setRowHeight(2, 10);

    // ─── COLUMN HEADERS ──────────────────────────
    final headers = [
      'S.No',
      'Product Name',
      'Product Code',
      'Category',
      'Brand',
      'Unit',
      'Selling Price (₹)',
      'Availability',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = subHeaderStyle;
    }
    sheet.setRowHeight(3, 28);

    // ─── PRODUCT DATA ────────────────────────────
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final rowIndex = i + 4;
      final isEven = i % 2 == 0;

      final rowData = [
        (i + 1).toString(),
        product.name,
        product.productCode,
        product.categoryName,
        product.brand,
        product.unit.toUpperCase(),
        product.currentPrice.sellingPrice.toStringAsFixed(0),
        _getAvailabilityText(product.availability),
      ];

      for (int j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: j,
            rowIndex: rowIndex,
          ),
        );
        cell.value = TextCellValue(rowData[j]);
        if (isEven) {
          cell.cellStyle = evenRowStyle;
        }
      }
      sheet.setRowHeight(rowIndex, 22);
    }

    // ─── COLUMN WIDTHS ───────────────────────────
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 20);
    sheet.setColumnWidth(7, 18);

    // Save
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/price_list_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  // ═══════════════════════════════════════
  // GENERATE REQUIREMENTS EXCEL (Admin)
  // ═══════════════════════════════════════
  static Future<File> generateRequirementsExcel({
    required List<RequirementModel> requirements,
    required String companyName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Requirements'];
    excel.delete('Sheet1');

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 11,
    );

    // Title
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('L1'),
    );
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('$companyName - Requirements Report');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle =
        CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    sheet.setRowHeight(0, 32);

    // Column headers
    final headers = [
      'S.No',
      'Date',
      'Product',
      'Trader',
      'Customer',
      'City',
      'Quantity',
      'Unit',
      'Current Price',
      'Demanded Price',
      'Offered Price',
      'Payment Type',
      'Status',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(2, 26);

    // Data
    for (int i = 0; i < requirements.length; i++) {
      final req = requirements[i];
      final rowIndex = i + 3;

      final rowData = [
        (i + 1).toString(),
        DateFormat('dd/MM/yyyy').format(req.submittedAt),
        req.productName,
        req.traderName,
        req.customerName,
        req.customerCity,
        req.quantity.toStringAsFixed(0),
        req.unit,
        req.productCurrentPrice.toStringAsFixed(0),
        req.customerDemandedPrice.toStringAsFixed(0),
        req.traderOfferedPrice.toStringAsFixed(0),
        _getPaymentText(req.paymentType),
        req.status.name.toUpperCase(),
      ];

      for (int j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: j,
            rowIndex: rowIndex,
          ),
        );
        cell.value = TextCellValue(rowData[j]);
      }
      sheet.setRowHeight(rowIndex, 20);
    }

    // Column widths
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 20);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 10);
    sheet.setColumnWidth(7, 8);
    sheet.setColumnWidth(8, 16);
    sheet.setColumnWidth(9, 18);
    sheet.setColumnWidth(10, 16);
    sheet.setColumnWidth(11, 18);
    sheet.setColumnWidth(12, 14);

    // Save
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/requirements_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  static String _getAvailabilityText(
      ProductAvailability availability) {
    return switch (availability) {
      ProductAvailability.inStock => 'In Stock',
      ProductAvailability.outOfStock => 'Out of Stock',
      ProductAvailability.limitedStock => 'Limited Stock',
    };
  }

  static String _getPaymentText(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => 'Full Cash',
      PaymentType.partialPayment => 'Partial Payment',
      PaymentType.credit => 'Credit',
    };
  }
}
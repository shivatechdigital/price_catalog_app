import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:price_catalog_app/data/models/app_settings_model.dart';
import 'package:price_catalog_app/data/models/product_model.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:http/http.dart' as http;

class PdfService {
  // ═══════════════════════════════════════
  // GENERATE PRODUCT CATALOG PDF
  // ═══════════════════════════════════════
  static Future<File> generateCatalogPdf({
    required List<ProductModel> products,
    required AppSettingsModel settings,
    bool showPrices = true,
  }) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load(
      'assets/fonts/Poppins-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Poppins-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    // Colors
    final primaryColor = PdfColor.fromHex('#1A237E');
    final accentColor = PdfColor.fromHex('#E65100');
    final lightGrey = PdfColor.fromHex('#F5F7FA');
    final textColor = PdfColor.fromHex('#1A1A2E');
    final subTextColor = PdfColor.fromHex('#6B7280');

    // Load product images
    final Map<String, pw.MemoryImage?> productImages = {};
    for (final product in products) {
      if (product.primaryImage.isNotEmpty) {
        try {
          final response = await http.get(
            Uri.parse(product.primaryImage),
          );
          if (response.statusCode == 200) {
            productImages[product.id] =
                pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {
          productImages[product.id] = null;
        }
      }
    }

    // ═══════════════════════════════════════
    // COVER PAGE
    // ═══════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [primaryColor, PdfColor.fromHex('#3949AB')],
              ),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      settings.companyName.isNotEmpty
                          ? settings.companyName[0].toUpperCase()
                          : 'C',
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  settings.companyName,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Product Catalog',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 48),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      if (settings.contactPhone.isNotEmpty)
                        _pdfInfoRow(
                          '📞',
                          settings.contactPhone,
                          subTextColor,
                        ),
                      if (settings.contactEmail.isNotEmpty)
                        _pdfInfoRow(
                          '✉️',
                          settings.contactEmail,
                          subTextColor,
                        ),
                      if (settings.address.isNotEmpty)
                        _pdfInfoRow(
                          '📍',
                          settings.address,
                          subTextColor,
                        ),
                      if (settings.gstNumber != null)
                        _pdfInfoRow(
                          '🏢',
                          'GST: ${settings.gstNumber}',
                          subTextColor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // ═══════════════════════════════════════
    // PRODUCTS PAGES
    // ═══════════════════════════════════════
    // 2 products per page
    for (int i = 0; i < products.length; i += 2) {
      final pageProducts = products.sublist(
        i,
        (i + 2) < products.length ? i + 2 : products.length,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: theme,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Page Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        settings.companyName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Page ${(i ~/ 2) + 2}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // Products Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: pageProducts.map((product) {
                    return pw.Expanded(
                      child: pw.Container(
                        margin: pw.EdgeInsets.only(
                          right:
                              pageProducts.indexOf(product) == 0
                                  ? 8
                                  : 0,
                          left:
                              pageProducts.indexOf(product) == 1
                                  ? 8
                                  : 0,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromHex('#E5E7EB'),
                          ),
                          borderRadius:
                              pw.BorderRadius.circular(12),
                        ),
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            pw.Container(
                              height: 160,
                              width: double.infinity,
                              decoration: pw.BoxDecoration(
                                color: lightGrey,
                                borderRadius:
                                    pw.BorderRadius.vertical(
                                  top: pw.Radius.circular(12),
                                ),
                              ),
                              child: productImages[product.id] !=
                                      null
                                  ? pw.Image(
                                      productImages[product.id]!,
                                      fit: pw.BoxFit.cover,
                                    )
                                  : pw.Center(
                                      child: pw.Text(
                                        product.categoryName[0],
                                        style: pw.TextStyle(
                                          fontSize: 48,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                            ),

                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.all(12),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  // Category
                                  pw.Container(
                                    padding:
                                        const pw.EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: primaryColor,
                                      borderRadius:
                                          pw.BorderRadius.circular(
                                              6),
                                    ),
                                    child: pw.Text(
                                      product.categoryName,
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: PdfColors.white,
                                        fontWeight:
                                            pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  // Product Name
                                  pw.Text(
                                    product.name,
                                    style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),

                                  pw.SizedBox(height: 3),

                                  // Brand + Code
                                  pw.Text(
                                    '${product.brand} • ${product.productCode}',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: subTextColor,
                                    ),
                                  ),

                                  if (product.description
                                      .isNotEmpty) ...[
                                    pw.SizedBox(height: 6),
                                    pw.Text(
                                      product.description.length >
                                              100
                                          ? '${product.description.substring(0, 100)}...'
                                          : product.description,
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],

                                  pw.SizedBox(height: 10),

                                  pw.Divider(
                                    color: PdfColor.fromHex(
                                      '#E5E7EB',
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  // Price (if showPrices)
                                  if (showPrices) ...[
                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        pw.Text(
                                          '${settings.currency}${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                                          style: pw.TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                pw.FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        pw.Text(
                                          'per ${product.unit}',
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Availability
                                  pw.SizedBox(height: 6),
                                  _availabilityWidget(
                                    product.availability,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    // ═══════════════════════════════════════
    // PRICE LIST PAGE
    // ═══════════════════════════════════════
    if (showPrices) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: theme,
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Price List - ${settings.companyName}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E5E7EB'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                  ),
                  children: [
                    _tableHeader('Product Name'),
                    _tableHeader('Code'),
                    _tableHeader('Category'),
                    _tableHeader('Price'),
                    _tableHeader('Unit'),
                  ],
                ),
                // Product Rows
                ...products.asMap().entries.map(
                  (entry) {
                    final isEven = entry.key % 2 == 0;
                    final product = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven
                            ? PdfColors.white
                            : PdfColor.fromHex('#F9FAFB'),
                      ),
                      children: [
                        _tableCell(product.name),
                        _tableCell(product.productCode),
                        _tableCell(product.categoryName),
                        _tableCell(
                          '${settings.currency}${product.currentPrice.sellingPrice.toStringAsFixed(0)}',
                        ),
                        _tableCell(product.unit),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 9,
                color: subTextColor,
              ),
            ),
          ),
        ),
      );
    }

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ═══════════════════════════════════════
  // GENERATE QUOTATION PDF
  // ═══════════════════════════════════════
  static Future<File> generateQuotationPdf({
    required RequirementModel requirement,
    required AppSettingsModel settings,
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load(
      'assets/fonts/Poppins-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Poppins-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    final primaryColor = PdfColor.fromHex('#1A237E');
    final textColor = PdfColor.fromHex('#1A1A2E');
    final subTextColor = PdfColor.fromHex('#6B7280');
    final lightGrey = PdfColor.fromHex('#F5F7FA');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───────────────────────────
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.companyName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (settings.address.isNotEmpty)
                        pw.Text(
                          settings.address,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                        ),
                      if (settings.contactPhone.isNotEmpty)
                        pw.Text(
                          settings.contactPhone,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius:
                              pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'QUOTATION',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: subTextColor,
                        ),
                      ),
                      pw.Text(
                        'Ref: #${requirement.id.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
              pw.SizedBox(height: 16),

              // ─── CUSTOMER & TRADER ─────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'QUOTATION FOR:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: subTextColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          requirement.customerBusinessName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.Text(
                          requirement.customerName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: subTextColor,
                          ),
                        ),
                        pw.Text(
                          requirement.customerCity,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                        ),
                        pw.Text(
                          requirement.customerPhone,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FROM TRADER:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: subTextColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          requirement.traderBusinessName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.Text(
                          requirement.traderName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: subTextColor,
                          ),
                        ),
                        pw.Text(
                          requirement.traderPhone?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ─── PRODUCT TABLE ─────────────────────
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#E5E7EB'),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: primaryColor),
                    children: [
                      _tableHeader('Product'),
                      _tableHeader('Qty'),
                      _tableHeader('Unit'),
                      _tableHeader('Rate'),
                      _tableHeader('Total'),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                    ),
                    children: [
                      _tableCell(requirement.productName),
                      _tableCell(
                        requirement.quantity.toStringAsFixed(0),
                      ),
                      _tableCell(requirement.unit),
                      _tableCell(
                        '₹${requirement.customerDemandedPrice.toStringAsFixed(0)}',
                      ),
                      _tableCell(
                        '₹${requirement.totalValue.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ─── TOTAL BOX ──────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Amount:',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '₹${requirement.totalValue.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // ─── PAYMENT INFO ───────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Terms',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _getPaymentLabel(
                        requirement.paymentType,
                      ),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: subTextColor,
                      ),
                    ),
                    if (requirement.traderNote != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Note: ${requirement.traderNote}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.Spacer(),

              // ─── FOOTER ─────────────────────────────
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business! | ${settings.companyName}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: subTextColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════
  static pw.Widget _pdfInfoRow(
      String emoji, String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text(emoji, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(width: 8),
          pw.Text(
            text,
            style: pw.TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _availabilityWidget(
      ProductAvailability availability) {
    final (color, text) = switch (availability) {
      ProductAvailability.inStock => (
          PdfColor.fromHex('#2E7D32'),
          'In Stock'
        ),
      ProductAvailability.outOfStock => (
          PdfColor.fromHex('#C62828'),
          'Out of Stock'
        ),
      ProductAvailability.limitedStock => (
          PdfColor.fromHex('#F57F17'),
          'Limited'
        ),
    };

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static String _getPaymentLabel(PaymentType type) {
    return switch (type) {
      PaymentType.fullCash => 'Full Cash Payment',
      PaymentType.partialPayment => 'Partial Payment',
      PaymentType.credit => 'Credit Payment',
    };
  }
}
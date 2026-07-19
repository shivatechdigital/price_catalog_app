import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:share_plus/share_plus.dart';

enum ExportRange { today, thisWeek, thisYear, all, custom }
enum ExportFormat { csv, pdf }

class RequirementExportService {
  static List<RequirementModel> filterRequirementsByRange(
    List<RequirementModel> requirements,
    ExportRange range, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    if (requirements.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    DateTime? start;
    DateTime? end;

    switch (range) {
      case ExportRange.today:
        start = today;
        end = tomorrow.subtract(const Duration(seconds: 1));
        break;
      case ExportRange.thisWeek:
        final weekday = now.weekday;
        start = today.subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case ExportRange.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case ExportRange.custom:
        start = customStart;
        end = customEnd;
        break;
      case ExportRange.all:
        return requirements;
    }

    if (start == null || end == null) {
      return requirements;
    }

    return requirements.where((req) {
      final submittedAt = req.submittedAt.toUtc();
      final startUtc = start!.toUtc();
      final endUtc = end!.toUtc();
      return !submittedAt.isBefore(startUtc) && !submittedAt.isAfter(endUtc);
    }).toList();
  }

  static String buildCsvContent(
    List<RequirementModel> requirements, {
    required String title,
  }) {
    final rows = <List<String>>[];
    rows.add([
      'Id',
      'Submitted At',
      'Status',
      'Trader',
      'Trader Business',
      'Customer',
      'Customer Phone',
      'Customer Business',
      'City',
      'Payment Type',
      'Credit Days',
      'Delivery Date',
      'Delivery Location',
      'Advance Amount',
      'Total Value',
      'Items Count',
      'Products',
      'Notes',
    ]);

    for (final requirement in requirements) {
      rows.add([
        requirement.id,
        DateFormat('dd MMM yyyy, HH:mm').format(requirement.submittedAt),
        _statusLabel(requirement.status),
        requirement.traderName,
        requirement.traderBusinessName,
        requirement.customerName,
        requirement.customerPhone,
        requirement.customerBusinessName,
        requirement.customerCity,
        _paymentLabel(requirement.paymentType),
        requirement.creditDays?.toString() ?? '',
        requirement.deliveryDate != null
            ? DateFormat('dd MMM yyyy').format(requirement.deliveryDate!)
            : '',
        requirement.deliveryLocation ?? '',
        requirement.advanceAmount?.toStringAsFixed(0) ?? '',
        requirement.totalValue.toStringAsFixed(0),
        requirement.items.length.toString(),
        requirement.items.map((item) => item.productName).join(' | '),
        [
          requirement.traderNote,
          requirement.adminNote,
        ].where((note) => note != null && note.isNotEmpty).join(' | '),
      ]);
    }

    final header = ['Export Title', title];
    final lines = <String>[
      _toCsvRow(header),
      _toCsvRow(rows.first),
      ...rows.skip(1).map(_toCsvRow),
    ];

    return lines.join('\n');
  }

  static Future<File> exportRequirementsToFile(
    List<RequirementModel> requirements, {
    required ExportRange range,
    DateTime? customStart,
    DateTime? customEnd,
    required String fileNamePrefix,
    ExportFormat format = ExportFormat.pdf,
  }) async {
    final filtered = filterRequirementsByRange(
      requirements,
      range,
      customStart: customStart,
      customEnd: customEnd,
    );

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = format == ExportFormat.pdf ? 'pdf' : 'csv';
    final fileName = '${fileNamePrefix}_${range.name}_$timestamp.$extension';
    final file = File('${Directory.systemTemp.path}/$fileName');

    if (format == ExportFormat.pdf) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final generatedAt = DateFormat('dd MMM yyyy, HH:mm').format(
              DateTime.now(),
            );

            return [
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Price Catalog',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Requirement Export',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey400),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Filter: ${_rangeLabel(range)}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Generated: $generatedAt',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Total: ${filtered.length}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              ...filtered.asMap().entries.expand((entry) {
                final requirement = entry.value;
                final index = entry.key + 1;
                final notes = [
                  requirement.traderNote,
                  requirement.adminNote,
                ].where((note) => note != null && note.isNotEmpty).join(' | ');
                final customerBusiness = requirement.customerBusinessName.isNotEmpty
                    ? requirement.customerBusinessName
                    : '-';
                final deliveryDate = requirement.deliveryDate != null
                    ? DateFormat('dd MMM yyyy').format(requirement.deliveryDate!)
                    : '-';
                final advanceAmount = requirement.advanceAmount != null
                    ? requirement.advanceAmount!.toStringAsFixed(0)
                    : '-';

                return [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '$index. ${requirement.id}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue50,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              child: pw.Text(
                                _statusLabel(requirement.status),
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.TableHelper.fromTextArray(
                          cellAlignment: pw.Alignment.centerLeft,
                          headerStyle: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          cellStyle: pw.TextStyle(fontSize: 9),
                          headerDecoration: const pw.BoxDecoration(
                            color: PdfColors.blue900,
                          ),
                          cellPadding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          data: [
                            [
                              'Trader',
                              '${requirement.traderName}\n${requirement.traderBusinessName}',
                            ],
                            [
                              'Customer',
                              '${requirement.customerName} / $customerBusiness\n${requirement.customerPhone}',
                            ],
                            [
                              'Payment',
                              '${_paymentLabel(requirement.paymentType)} - ${requirement.creditDays ?? '-'} days',
                            ],
                            [
                              'Delivery',
                              '$deliveryDate - ${requirement.deliveryLocation ?? '-'}',
                            ],
                            [
                              'Advance',
                              advanceAmount,
                            ],
                            [
                              'Total',
                              requirement.totalValue.toStringAsFixed(0),
                            ],
                          ],
                        ),
                        if (requirement.items.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Items',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.TableHelper.fromTextArray(
                            headerStyle: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            headerDecoration: const pw.BoxDecoration(
                              color: PdfColors.grey800,
                            ),
                            cellAlignment: pw.Alignment.centerLeft,
                            cellStyle: pw.TextStyle(fontSize: 8),
                            rowDecoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                            ),
                            headers: [
                              'Product',
                              'Qty',
                              'Unit',
                              'Rate',
                              'Final',
                            ],
                            data: requirement.items.map((item) {
                              return [
                                item.productName,
                                item.quantity.toStringAsFixed(0),
                                item.unit,
                                item.customerDemandedPrice.toStringAsFixed(0),
                                item.finalPrice.toStringAsFixed(0),
                              ];
                            }).toList(),
                          ),
                        ],
                        if (notes.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Notes',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(notes, style: pw.TextStyle(fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
                ];
              }),
            ];
          },
        ),
      );
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    }

    await file.writeAsString(
      buildCsvContent(filtered, title: _rangeLabel(range)),
      flush: true,
    );
    return file;
  }

  static Future<bool> shareRequirementsExport(
    List<RequirementModel> requirements, {
    required ExportRange range,
    DateTime? customStart,
    DateTime? customEnd,
    required String fileNamePrefix,
    ExportFormat format = ExportFormat.pdf,
  }) async {
    try {
      final file = await exportRequirementsToFile(
        requirements,
        range: range,
        customStart: customStart,
        customEnd: customEnd,
        fileNamePrefix: fileNamePrefix,
        format: format,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Requirements Export',
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _rangeLabel(ExportRange range) {
    return switch (range) {
      ExportRange.today => 'Today',
      ExportRange.thisWeek => 'This Week',
      ExportRange.thisYear => 'This Year',
      ExportRange.all => 'All Data',
      ExportRange.custom => 'Custom Range',
    };
  }

  static String _statusLabel(RequirementStatus status) {
    return switch (status) {
      RequirementStatus.pending => 'Pending',
      RequirementStatus.approved => 'Approved',
      RequirementStatus.rejected => 'Rejected',
      RequirementStatus.counterOffer => 'Counter Offer',
    };
  }

  static String _paymentLabel(PaymentType paymentType) {
    return switch (paymentType) {
      PaymentType.fullCash => 'Full Cash',
      PaymentType.partialPayment => 'Partial Payment',
      PaymentType.credit => 'Credit',
    };
  }

  static String _toCsvRow(List<String> values) {
    final escaped = values.map((value) => value.replaceAll('"', '""')).toList();

    return escaped
        .map((value) {
          final needsQuotes =
              value.contains(',') ||
              value.contains('"') ||
              value.contains('\n');
          return needsQuotes ? '"$value"' : value;
        })
        .join(',');
  }
}

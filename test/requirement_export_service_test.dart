import 'package:flutter_test/flutter_test.dart';
import 'package:price_catalog_app/core/services/requirement_export_service.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

void main() {
  group('RequirementExportService', () {
    late RequirementModel older;
    late RequirementModel today;
    late RequirementModel thisWeek;

    setUp(() {
      older = RequirementModel(
        id: 'old',
        traderId: 't1',
        traderName: 'Trader',
        traderBusinessName: 'Biz',
        items: const [],
        customerName: 'Cust',
        customerPhone: '',
        customerBusinessName: '',
        customerCity: '',
        paymentType: PaymentType.fullCash,
        status: RequirementStatus.pending,
        submittedAt: DateTime(2024, 1, 1),
      );

      today = RequirementModel(
        id: 'today',
        traderId: 't1',
        traderName: 'Trader',
        traderBusinessName: 'Biz',
        items: const [],
        customerName: 'Cust',
        customerPhone: '',
        customerBusinessName: '',
        customerCity: '',
        paymentType: PaymentType.fullCash,
        status: RequirementStatus.approved,
        submittedAt: DateTime.now(),
      );

      thisWeek = RequirementModel(
        id: 'week',
        traderId: 't1',
        traderName: 'Trader',
        traderBusinessName: 'Biz',
        items: const [],
        customerName: 'Cust',
        customerPhone: '',
        customerBusinessName: '',
        customerCity: '',
        paymentType: PaymentType.fullCash,
        status: RequirementStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
    });

    test('filters today exports correctly', () {
      final filtered = RequirementExportService.filterRequirementsByRange([
        older,
        today,
        thisWeek,
      ], ExportRange.today);

      expect(filtered.map((e) => e.id), contains('today'));
      expect(filtered.map((e) => e.id), isNot(contains('old')));
    });

    test('filters custom range exports correctly', () {
      final now = DateTime.now();
      final filtered = RequirementExportService.filterRequirementsByRange(
        [older, today, thisWeek],
        ExportRange.custom,
        customStart: now.subtract(const Duration(days: 7)),
        customEnd: now,
      );

      expect(filtered.map((e) => e.id), contains('week'));
      expect(filtered.map((e) => e.id), contains('today'));
      expect(filtered.map((e) => e.id), isNot(contains('old')));
    });

    test('exports a PDF file when requested', () async {
      final file = await RequirementExportService.exportRequirementsToFile(
        [today],
        range: ExportRange.all,
        fileNamePrefix: 'test_export',
        format: ExportFormat.pdf,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.pdf'), isTrue);
      await file.delete();
    });
  });
}

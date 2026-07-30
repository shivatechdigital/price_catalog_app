import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;

class TraderReportsScreen extends ConsumerStatefulWidget {
  const TraderReportsScreen({super.key});

  @override
  ConsumerState<TraderReportsScreen> createState() =>
      _TraderReportsScreenState();
}

class _TraderReportsScreenState extends ConsumerState<TraderReportsScreen> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox();

    final requirementsAsync =
        ref.watch(traderRequirementsProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── App Bar ────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.traderPrimary,
            expandedHeight: 120.h,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: 20.sp,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.traderGradient,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.chart_2,
                          color: AppColors.white,
                          size: 22.sp,
                        ),
                        Gap(8.w),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Reports',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              currentUser.name,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Export PDF
              GestureDetector(
                onTap: requirementsAsync.asData?.value != null
                    ? () => _exportPdf(requirementsAsync.asData!.value!)
                    : null,
                child: Container(
                  margin: EdgeInsets.only(right: 8.w, top: 8.h, bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: _exportingPdf
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(children: [
                          Icon(Iconsax.document_download,
                              size: 16.sp, color: AppColors.white),
                          Gap(4.w),
                          Text('PDF',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
              // Export Excel
              GestureDetector(
                onTap: requirementsAsync.asData?.value != null
                    ? () => _exportExcel(requirementsAsync.asData!.value!)
                    : null,
                child: Container(
                  margin: EdgeInsets.only(right: 16.w, top: 8.h, bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: _exportingExcel
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(children: [
                          Icon(Iconsax.document_download,
                              size: 16.sp, color: AppColors.white),
                          Gap(4.w),
                          Text('Excel',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: requirementsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) =>
                  const Center(child: Text('Failed to load reports')),
              data: (requirements) => _buildContent(requirements),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<RequirementModel> requirements) {
    final total = requirements.length;
    final approved =
        requirements.where((r) => r.status == RequirementStatus.approved).length;
    final rejected =
        requirements.where((r) => r.status == RequirementStatus.rejected).length;
    final pending =
        requirements.where((r) => r.status == RequirementStatus.pending).length;
    final counter = requirements
        .where((r) => r.status == RequirementStatus.counterOffer)
        .length;

    final totalValue = requirements
        .where((r) => r.status == RequirementStatus.approved)
        .fold<double>(
          0,
          (sum, r) => sum +
              r.items.fold<double>(
                  0, (s, i) => s + (i.traderOfferedPrice * i.quantity)),
        );

    // Monthly data (last 6 months)
    final now = DateTime.now();
    final monthlyData = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final count = requirements
          .where((r) =>
              r.submittedAt.year == month.year &&
              r.submittedAt.month == month.month)
          .length;
      return _MonthData(DateFormat('MMM').format(month), count);
    });

    // Top customers
    final customerCounts = <String, int>{};
    final customerValues = <String, double>{};
    for (final r in requirements) {
      customerCounts[r.customerName] =
          (customerCounts[r.customerName] ?? 0) + 1;
      customerValues[r.customerName] = (customerValues[r.customerName] ?? 0) +
          r.items.fold<double>(
              0, (s, i) => s + (i.traderOfferedPrice * i.quantity));
    }
    final topCustomers = customerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top products ordered
    final productCounts = <String, int>{};
    for (final r in requirements) {
      for (final item in r.items) {
        productCounts[item.productName] =
            (productCounts[item.productName] ?? 0) + 1;
      }
    }
    final topProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap(16.h),

        // ─── Stats Grid ──────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total',
                  value: '$total',
                  icon: Iconsax.document_text,
                  color: AppColors.traderPrimary,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: _StatCard(
                  label: 'Approved',
                  value: '$approved',
                  icon: Iconsax.tick_circle,
                  color: AppColors.approved,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: Iconsax.clock,
                  color: AppColors.counter,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),

        Gap(10.h),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Rejected',
                  value: '$rejected',
                  icon: Iconsax.close_circle,
                  color: AppColors.rejected,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: _StatCard(
                  label: 'Counter',
                  value: '$counter',
                  icon: Iconsax.refresh,
                  color: AppColors.traderPrimary,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: _StatCard(
                  label: 'Customers',
                  value: '${customerCounts.length}',
                  icon: Iconsax.people,
                  color: AppColors.adminPrimary,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

        Gap(16.h),

        // ─── Total Earned Card ───────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: AppColors.traderGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.traderPrimary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Approved Deal Value',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                Gap(6.h),
                Text(
                  '₹${NumberFormat('#,##,###').format(totalValue.toInt())}',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                Gap(4.h),
                Text(
                  'From $approved approved requirements',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),

        Gap(20.h),

        // ─── Monthly Trend ───────────────────────
        _SectionCard(
          title: 'Monthly Activity',
          subtitle: 'Requirements submitted last 6 months',
          icon: Iconsax.chart_1,
          color: AppColors.traderPrimary,
          child: _MonthlyBarChart(
              data: monthlyData, color: AppColors.traderPrimary),
        ).animate().fadeIn(delay: 200.ms),

        Gap(12.h),

        // ─── Status Breakdown ────────────────────
        _SectionCard(
          title: 'Status Breakdown',
          subtitle: 'My requirement distribution',
          icon: Iconsax.chart_21,
          color: AppColors.traderPrimary,
          child: total == 0
              ? _emptyState('No requirements yet')
              : Column(
                  children: [
                    _StatusBar(
                        label: 'Approved',
                        count: approved,
                        total: total,
                        color: AppColors.approved),
                    Gap(10.h),
                    _StatusBar(
                        label: 'Pending',
                        count: pending,
                        total: total,
                        color: AppColors.counter),
                    Gap(10.h),
                    _StatusBar(
                        label: 'Rejected',
                        count: rejected,
                        total: total,
                        color: AppColors.rejected),
                    Gap(10.h),
                    _StatusBar(
                        label: 'Counter',
                        count: counter,
                        total: total,
                        color: AppColors.traderPrimary),
                  ],
                ),
        ).animate().fadeIn(delay: 250.ms),

        Gap(12.h),

        // ─── Top Customers ───────────────────────
        _SectionCard(
          title: 'Top Customers',
          subtitle: 'By number of requirements',
          icon: Iconsax.shop,
          color: AppColors.traderPrimary,
          child: topCustomers.isEmpty
              ? _emptyState('No customers yet')
              : Column(
                  children: topCustomers
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _RankRow(
                            rank: e.key + 1,
                            label: e.value.key,
                            value: '${e.value.value} orders',
                            color: AppColors.traderPrimary,
                            max: topCustomers.first.value.toDouble(),
                            current: e.value.value.toDouble(),
                          ))
                      .toList(),
                ),
        ).animate().fadeIn(delay: 300.ms),

        Gap(12.h),

        // ─── Top Products ────────────────────────
        _SectionCard(
          title: 'Top Products Ordered',
          subtitle: 'Products you order most',
          icon: Iconsax.box,
          color: AppColors.adminPrimary,
          child: topProducts.isEmpty
              ? _emptyState('No orders yet')
              : Column(
                  children: topProducts
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _RankRow(
                            rank: e.key + 1,
                            label: e.value.key,
                            value: '${e.value.value} times',
                            color: AppColors.adminPrimary,
                            max: topProducts.first.value.toDouble(),
                            current: e.value.value.toDouble(),
                          ))
                      .toList(),
                ),
        ).animate().fadeIn(delay: 350.ms),

        Gap(40.h),
      ],
    );
  }

  Widget _emptyState(String msg) => Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(msg,
              style:
                  TextStyle(fontSize: 13.sp, color: AppColors.textHint)),
        ),
      );

  // ═══════════════════════════════════════
  // EXPORT PDF
  // ═══════════════════════════════════════
  Future<void> _exportPdf(List<RequirementModel> requirements) async {
    setState(() => _exportingPdf = true);
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final fmt = DateFormat('dd MMM yyyy');
      final currentUser = ref.read(currentUserProvider);

      final approved = requirements
          .where((r) => r.status == RequirementStatus.approved)
          .length;
      final rejected = requirements
          .where((r) => r.status == RequirementStatus.rejected)
          .length;
      final pending = requirements
          .where((r) => r.status == RequirementStatus.pending)
          .length;
      final totalValue = requirements
          .where((r) => r.status == RequirementStatus.approved)
          .fold<double>(
              0,
              (sum, r) => sum +
                  r.items.fold<double>(
                      0, (s, i) => s + (i.traderOfferedPrice * i.quantity)));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'My Business Report - ${currentUser?.name ?? ''}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1565C0'),
                ),
              ),
            ),
            pw.Text('Generated: ${fmt.format(now)}',
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColor.fromHex('#6B7280'))),
            pw.SizedBox(height: 20),
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Total Requirements', '${requirements.length}'],
                ['Approved', '$approved'],
                ['Rejected', '$rejected'],
                ['Pending', '$pending'],
                [
                  'Total Deal Value',
                  '₹${NumberFormat('#,##,###').format(totalValue.toInt())}'
                ],
              ],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FFFFFF')),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1565C0)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('My Requirements',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Customer', 'Products', 'Status', 'Date'],
              data: requirements.take(30).map((r) {
                return [
                  r.customerName,
                  r.items.map((i) => i.productName).join(', '),
                  r.status.name.toUpperCase(),
                  fmt.format(r.submittedAt),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FFFFFF')),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1565C0)),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/my_report_${DateFormat('yyyyMMdd').format(now)}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf')],
            subject: 'My Business Report',
          ),
        );
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Failed to export PDF');
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  // ═══════════════════════════════════════
  // EXPORT EXCEL
  // ═══════════════════════════════════════
  Future<void> _exportExcel(List<RequirementModel> requirements) async {
    setState(() => _exportingExcel = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['My Requirements'];
      excel.delete('Sheet1');

      final hStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      final headers = [
        'Customer',
        'Business',
        'City',
        'Products',
        'Status',
        'Payment',
        'Date',
      ];
      for (int c = 0; c < headers.length; c++) {
        _cell(sheet, 0, c, headers[c], hStyle);
      }

      final fmt = DateFormat('dd/MM/yyyy');
      for (int i = 0; i < requirements.length; i++) {
        final r = requirements[i];
        _cell(sheet, i + 1, 0, r.customerName, null);
        _cell(sheet, i + 1, 1, r.customerBusinessName, null);
        _cell(sheet, i + 1, 2, r.customerCity, null);
        _cell(sheet, i + 1, 3,
            r.items.map((item) => item.productName).join(', '), null);
        _cell(sheet, i + 1, 4, r.status.name.toUpperCase(), null);
        _cell(sheet, i + 1, 5, r.paymentType.name, null);
        _cell(sheet, i + 1, 6, fmt.format(r.submittedAt), null);
      }

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final file = File(
          '${dir.path}/my_report_${DateFormat('yyyyMMdd').format(now)}.xlsx');
      final bytes = excel.encode();
      if (bytes != null) await file.writeAsBytes(bytes);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(file.path,
                  mimeType:
                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ],
            subject: 'My Business Report',
          ),
        );
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Failed to export Excel');
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  void _cell(Sheet sheet, int row, int col, String value, CellStyle? style) {
    final cell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    if (style != null) cell.cellStyle = style;
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────
class _MonthData {
  final String month;
  final int count;
  _MonthData(this.month, this.count);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
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
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 17.sp, color: color),
          ),
          Gap(10.h),
          Text(value,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  const _SectionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: color),
              Gap(8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11.sp, color: AppColors.textHint)),
                  ],
                ),
              ),
            ],
          ),
          Gap(14.h),
          child,
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthData> data;
  final Color color;
  const _MonthlyBarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final ratio = maxVal > 0 ? d.count / maxVal : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Column(
              children: [
                Text('${d.count}',
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Gap(4.h),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: (80 * ratio + 4).h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color, color.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                Gap(6.h),
                Text(d.month,
                    style:
                        TextStyle(fontSize: 10.sp, color: AppColors.textHint)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String label;
  final String value;
  final Color color;
  final double max;
  final double current;
  const _RankRow(
      {required this.rank,
      required this.label,
      required this.value,
      required this.color,
      required this.max,
      required this.current});

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? current / max : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: rank <= 3 ? color : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: rank <= 3 ? AppColors.white : AppColors.textHint)),
            ),
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(value,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: color,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                Gap(4.h),
                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _StatusBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 70.w,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.sp, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8.h,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        Gap(10.w),
        Text('${(pct * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color)),
        Gap(4.w),
        Text('($count)',
            style: TextStyle(fontSize: 11.sp, color: AppColors.textHint)),
      ],
    );
  }
}

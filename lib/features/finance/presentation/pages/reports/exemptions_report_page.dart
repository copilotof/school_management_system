import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import '../../../../students/presentation/bloc/students_state.dart';

class _Gap {
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 تقرير الإعفاءات والتخفيضات
class ExemptionsReportPage extends StatefulWidget {
  const ExemptionsReportPage({super.key});

  @override
  State<ExemptionsReportPage> createState() => _ExemptionsReportPageState();
}

class _ExemptionsReportPageState extends State<ExemptionsReportPage> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, 1, 1);
    _toDate = DateTime(now.year, 12, 31);
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      minDate: DateTime(2020),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  /// ✅ فلترة الإعفاءات
  List<PaymentEntity> _filterPayments(List<PaymentEntity> all) {
    return all.where((p) {
      // فقط الإعفاءات والتخفيضات
      if (p.type != 'exemption' && p.type != 'reduction') return false;
      // في الفترة
      if (p.paymentDate.isBefore(_fromDate) || p.paymentDate.isAfter(_toDate)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  /// ✅ حساب قيمة الإعفاء
  double _getExemptionAmount(PaymentEntity p) {
    if (p.type == 'exemption') {
      return p.originalAmount; // إعفاء كامل
    }
    // تخفيض: الفرق
    return p.originalAmount - p.amount;
  }

  /// ✅ تحميل الخط
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ توليد PDF
  Future<Uint8List> _generatePdf(
    BuildContext context,
    List<PaymentEntity> payments,
  ) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final now = DateTime.now();
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];

    final total = payments.fold<double>(
      0,
      (sum, p) => sum + _getExemptionAmount(p),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context ctx) {
          return [
            // الرأس
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تقرير الإعفاءات والتخفيضات',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Exemptions & Reductions Report',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'من: ${DateFormat('yyyy/MM/dd').format(_fromDate)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'إلى: ${DateFormat('yyyy/MM/dd').format(_toDate)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // الملخص
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.orange800, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _pdfSummaryRow(
                    'عدد الإعفاءات/التخفيضات',
                    '${payments.length}',
                    PdfColors.blue800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    'إجمالي المبالغ المعفاة',
                    '${total.toStringAsFixed(0)} دج',
                    PdfColors.orange800,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // الجدول
            pw.Text(
              'تفاصيل الإعفاءات',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 8),

            if (payments.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'لا توجد إعفاءات في الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.orange50,
                    ),
                    children: [
                      _pdfTableHeader('#'),
                      _pdfTableHeader('الطالب'),
                      _pdfTableHeader('النوع'),
                      _pdfTableHeader('المطلوب'),
                      _pdfTableHeader('المبلغ المعفى'),
                    ],
                  ),
                  ...payments.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final p = entry.value;
                    final student = students
                        .where((s) => s.id == p.studentId)
                        .firstOrNull;
                    final exemptedAmount = _getExemptionAmount(p);

                    return pw.TableRow(
                      children: [
                        _pdfTableCell('$i'),
                        _pdfTableCell(
                          student?.fullName ?? '-',
                          align: pw.TextAlign.right,
                        ),
                        _pdfTableCell(p.typeLabel),
                        _pdfTableCell(
                          '${p.originalAmount.toStringAsFixed(0)} دج',
                        ),
                        _pdfTableCell(
                          '${exemptedAmount.toStringAsFixed(0)} دج',
                          color: PdfColors.orange800,
                        ),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'تاريخ الطباعة: ${DateFormat('yyyy/MM/dd HH:mm').format(now)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfSummaryRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.orange800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _pdfTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: color),
        textAlign: align,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        final allPayments = state.paymentsState.data ?? [];
        final payments = _filterPayments(allPayments);
        final total = payments.fold<double>(
          0,
          (sum, p) => sum + _getExemptionAmount(p),
        );

        return Column(
          children: [
            _buildDateFilter(colors),
            _buildSummary(colors, payments.length, total),
            Expanded(child: _buildList(context, payments, colors)),
            _buildBottomBar(context, payments),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter(ColorScheme colors) {
    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'من',
                  prefixIcon: Icon(Icons.calendar_today, size: 16),
                  isDense: true,
                ),
                child: Text(
                  DateFormat('yyyy/MM/dd').format(_fromDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'إلى',
                  prefixIcon: Icon(Icons.calendar_today, size: 16),
                  isDense: true,
                ),
                child: Text(
                  DateFormat('yyyy/MM/dd').format(_toDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme colors, int count, double total) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'عدد الإعفاءات',
              value: '$count',
              color: colors.primary,
              icon: Icons.card_giftcard,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _StatCard(
              label: 'إجمالي المعفى',
              value: '${total.toStringAsFixed(0)} دج',
              color: colors.tertiary,
              icon: Icons.redeem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<PaymentEntity> payments,
    ColorScheme colors,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64.sp,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              'لا توجد إعفاءات في هذه الفترة',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<StudentsBloc, StudentsState>(
      builder: (context, studentsState) {
        final students = studentsState.studentsState.data ?? [];

        return ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index];
            final student = students
                .where((s) => s.id == p.studentId)
                .firstOrNull;
            final exemptedAmount = _getExemptionAmount(p);
            final isExemption = p.type == 'exemption';

            return Card(
              margin: EdgeInsets.only(bottom: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(color: colors.tertiary.withOpacity(0.3)),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16.r,
                  backgroundColor: colors.tertiaryContainer,
                  child: Icon(
                    isExemption ? Icons.card_giftcard : Icons.percent,
                    size: 16.sp,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                title: Text(
                  student?.fullName ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${p.typeLabel} • ${DateFormat('yyyy/MM/dd').format(p.paymentDate)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${exemptedAmount.toStringAsFixed(0)} دج',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.tertiary,
                      ),
                    ),
                    if (!isExemption)
                      Text(
                        'دفع ${p.amount.toStringAsFixed(0)} دج',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, List<PaymentEntity> payments) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfBytes = await _generatePdf(context, payments);
                    await Printing.layoutPdf(
                      onLayout: (format) async => pdfBytes,
                    );
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('طباعة'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kRadius),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final pdfBytes = await _generatePdf(context, payments);
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'exemptions_report.pdf',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kRadius),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 بطاقة إحصائية
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

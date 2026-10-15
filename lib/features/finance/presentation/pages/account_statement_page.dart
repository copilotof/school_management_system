import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

// ثوابت التصميم
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة كشف حساب الطالب في فوج معين
class AccountStatementPage extends StatelessWidget {
  final StudentEntity student;
  final GroupEntity group;

  const AccountStatementPage({
    super.key,
    required this.student,
    required this.group,
  });

  /// ✅ تحميل الخط العربي
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ جلب دفعات الطالب في هذا الفوج
  List<PaymentEntity> _getPayments(FinanceState state) {
    return (state.paymentsState.data ?? [])
        .where((p) => p.studentId == student.id && p.groupId == group.id)
        .toList()
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
  }

  /// ✅ توليد PDF كشف الحساب
  Future<Uint8List> _generatePdf(
    BuildContext context,
    List<PaymentEntity> payments,
  ) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final now = DateTime.now();

    // ✅ حساب الملخص
    final totalPaid = payments
        .where((p) => p.type != 'exemption' && p.type != 'extra')
        .fold<double>(0, (sum, p) => sum + p.amount);

    final totalExempted = payments
        .where((p) => p.type == 'exemption' || p.type == 'reduction')
        .fold<double>(0, (sum, p) {
          if (p.type == 'exemption') return sum + p.originalAmount;
          return sum + (p.originalAmount - p.amount);
        });

    final totalRemaining = payments
        .where((p) => p.remainingAmount > 0 && p.type != 'extra_payment')
        .fold<double>(0, (sum, p) => sum + p.remainingAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context ctx) {
          return [
            // ====== الرأس ======
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        context.tr('reports.accountStatement'),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Account Statement',
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
                        '${context.tr('reports.printDate')}: ${context.formatDate(now)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${context.tr('reports.printTime')}: ${context.formatTime(now)}',
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

            // ====== معلومات الطالب ======
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    context.tr('reports.studentInfo'),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfInfoRow(
                              context.tr('reports.nameLabel'),
                              student.fullName,
                            ),
                            _pdfInfoRow(
                              context.tr('reports.codeLabel'),
                              student.studentCode,
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfInfoRow(
                              context.tr('reports.groupLabel'),
                              group.name,
                            ),
                            _pdfInfoRow(
                              context.tr('groups.monthlyFee'),
                              '${group.monthlyFee.toStringAsFixed(0)} ${context.tr('common.currency')}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ====== جدول الدفعات ======
            pw.Text(
              context.tr('reports.details'),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),

            if (payments.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  context.tr('reports.noPayments'),
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
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // الرأس
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _pdfTableHeader(context.tr('common.date')),
                      _pdfTableHeader(context.tr('reports.typeLabel')),
                      _pdfTableHeader(context.tr('reports.monthLabel')),
                      _pdfTableHeader(context.tr('reports.dueLabel')),
                      _pdfTableHeader(context.tr('reports.paidLabel')),
                      _pdfTableHeader(context.tr('reports.remainingLabel')),
                    ],
                  ),
                  // الصفوف
                  ...payments.map(
                    (p) => pw.TableRow(
                      children: [
                        _pdfTableCell(
                          DateFormat('yyyy/MM/dd').format(p.paymentDate),
                        ),
                        _pdfTableCell(context.tr(p.typeKey)),
                        _pdfTableCell(p.monthYear ?? '-'),
                        _pdfTableCell(
                          '${p.originalAmount.toStringAsFixed(0)} ${context.tr('common.currency')}',
                        ),
                        _pdfTableCell(
                          p.type == 'exemption'
                              ? context.tr('reports.exempted')
                              : '${p.amount.toStringAsFixed(0)} ${context.tr('common.currency')}',
                        ),
                        _pdfTableCell(
                          p.remainingAmount > 0
                              ? '${p.remainingAmount.toStringAsFixed(0)} ${context.tr('common.currency')}'
                              : '-',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            pw.SizedBox(height: 16),

            // ====== الملخص ======
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _pdfSummaryRow(
                    context.tr('reports.totalPaidLabel'),
                    '${totalPaid.toStringAsFixed(0)} ${context.tr('common.currency')}',
                    PdfColors.green800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    context.tr('reports.totalExempted'),
                    '${totalExempted.toStringAsFixed(0)} ${context.tr('common.currency')}',
                    PdfColors.orange800,
                  ),
                  pw.Divider(color: PdfColors.blue800, thickness: 1),
                  _pdfSummaryRow(
                    context.tr('reports.remainingLabel'),
                    '${totalRemaining.toStringAsFixed(0)} ${context.tr('common.currency')}',
                    totalRemaining > 0 ? PdfColors.red800 : PdfColors.green800,
                    isBold: true,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // =====️ التوقيع ======
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.grey700),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Center(
                        child: pw.Text(
                          context.tr('reports.accountantSignature'),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.grey700),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Center(
                        child: pw.Text(
                          context.tr('reports.schoolStamp'),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// ✅ صف معلومات في PDF
  static pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ✅ رأس جدول PDF
  static pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// ✅ خلية جدول PDF
  static pw.Widget _pdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// ✅ صف ملخص PDF
  static pw.Widget _pdfSummaryRow(
    String label,
    String value,
    PdfColor color, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 13 : 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reports.accountStatement'))),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          final payments = _getPayments(state);

          // حسابات
          final totalPaid = payments
              .where((p) => p.type != 'exemption' && p.type != 'extra')
              .fold<double>(0, (sum, p) => sum + p.amount);

          final totalExempted = payments
              .where((p) => p.type == 'exemption' || p.type == 'reduction')
              .fold<double>(0, (sum, p) {
                if (p.type == 'exemption') return sum + p.originalAmount;
                return sum + (p.originalAmount - p.amount);
              });

          final totalRemaining = payments
              .where((p) => p.remainingAmount > 0 && p.type != 'extra_payment')
              .fold<double>(0, (sum, p) => sum + p.remainingAmount);

          return Column(
            children: [
              // =====️ معاينة على الشاشة =====
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // بطاقة معلومات الطالب
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  '${context.tr('reports.codeLabel')}: ${student.studentCode}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  '${context.tr('reports.groupLabel')}: ${group.name}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _Gap.md),

                      // الملخص
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: context.tr('reports.paidLabel'),
                              value:
                                  '${totalPaid.toStringAsFixed(0)} ${context.tr('common.currency')}',
                              color: colors.secondary,
                              icon: Icons.check_circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SummaryCard(
                              label: context.tr('reports.exemptedLabel'),
                              value:
                                  '${totalExempted.toStringAsFixed(0)} ${context.tr('common.currency')}',
                              color: colors.tertiary,
                              icon: Icons.card_giftcard,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SummaryCard(
                              label: context.tr('reports.remainingLabel'),
                              value:
                                  '${totalRemaining.toStringAsFixed(0)} ${context.tr('common.currency')}',
                              color: totalRemaining > 0
                                  ? colors.error
                                  : colors.secondary,
                              icon: Icons.warning_amber,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _Gap.md),

                      // جدول الدفعات
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 16.sp,
                                    color: colors.primary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    context.tr('reports.details'),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              if (payments.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(20.w),
                                  child: Text(
                                    context.tr('reports.noPayments'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              else
                                ...payments.map((p) => _PaymentRow(payment: p)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ====== الشريط السفلي ======
              Container(
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
                              final pdfBytes = await _generatePdf(
                                context,
                                payments,
                              );
                              await Printing.layoutPdf(
                                onLayout: (format) async => pdfBytes,
                              );
                            },
                            icon: const Icon(Icons.print, size: 18),
                            label: Text(context.tr('reports.print')),
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
                              final pdfBytes = await _generatePdf(
                                context,
                                payments,
                              );
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename:
                                    'statement_${student.studentCode}_${group.id}.pdf',
                              );
                            },
                            icon: const Icon(Icons.share, size: 16),
                            label: Text(
                              context.tr('reports.share'),
                              style: TextStyle(fontSize: 12),
                            ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 📊 بطاقة ملخص
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 📄 صف دفعة
class _PaymentRow extends StatelessWidget {
  final PaymentEntity payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isExemption =
        payment.type == 'exemption' || payment.type == 'reduction';

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            isExemption ? Icons.card_giftcard : Icons.payments,
            size: 16.sp,
            color: isExemption ? colors.tertiary : colors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(payment.typeKey),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${payment.monthYear ?? ''} • ${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(0)} ${context.tr('common.currency')}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isExemption ? colors.tertiary : colors.secondary,
                ),
              ),
              if (payment.remainingAmount > 0)
                Text(
                  '${context.tr('reports.remainingLabel')}: ${payment.remainingAmount.toStringAsFixed(0)} ${context.tr('common.currency')}',
                  style: TextStyle(fontSize: 9.sp, color: colors.error),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

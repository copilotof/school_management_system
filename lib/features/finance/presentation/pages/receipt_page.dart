import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

// ============================================================
// 🎨 نظام تصميم محلي (خاص بهذا الملف) — Material 3
// ============================================================
class _Sp {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
  static double get xl => 24.h;
}

class _Rad {
  static double get card => 18.r;
  static double get field => 12.r;
  static double get chip => 100.r;
}

/// 📁 صفحة الإيصال - معاينة + طباعة
class ReceiptPage extends StatefulWidget {
  final PaymentEntity payment;
  final StudentEntity student;

  const ReceiptPage({super.key, required this.payment, required this.student});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _isGenerating = false;

  PaymentEntity get payment => widget.payment;
  StudentEntity get student => widget.student;

  /// ✅ تحميل الخط العربي
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ رقم الإيصال
  String _formatReceiptNumber() => payment.receiptNumber;

  /// ✅ تسمية طريقة الدفع
  static String _methodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقداً';
      case 'bank_transfer':
        return 'تحويل بنكي';
      case 'check':
        return 'شيك';
      default:
        return 'أخرى';
    }
  }

  /// ✅ توليد PDF الإيصال
  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final group = groups.where((g) => g.id == payment.groupId).firstOrNull;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ====== الرأس ======
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'إيصال دفع',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Payment Receipt',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'رقم الإيصال',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            _formatReceiptNumber(),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.blue800, thickness: 1.5),
                pw.SizedBox(height: 12),

                // ====== التاريخ ======
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'التاريخ: ${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'الوقت: ${DateFormat('HH:mm').format(payment.paymentDate)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
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
                        'معلومات الطالب',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _pdfInfoRow('الاسم', student.fullName),
                      _pdfInfoRow('الرقم', student.studentCode),
                      if (group != null) _pdfInfoRow('الفوج', group.name),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // ====== تفاصيل الدفعة ======
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blueGrey200),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تفاصيل الدفعة',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _pdfInfoRow('نوع الدفعة', payment.typeLabel),
                      if (payment.monthYear != null)
                        _pdfInfoRow('الشهر', payment.monthYear!),
                      _pdfInfoRow('طريقة الدفع', _methodLabel(payment.method)),
                      if (payment.notes != null)
                        _pdfInfoRow('ملاحظات', payment.notes!),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // ====== المبالغ ======
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'المبلغ الإجمالي',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            '${payment.originalAmount.toStringAsFixed(0)} دج',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'المبلغ المدفوع',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                          pw.Text(
                            '${payment.amount.toStringAsFixed(0)} دج',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                      if (payment.remainingAmount > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'المتبقي',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.red800,
                              ),
                            ),
                            pw.Text(
                              '${payment.remainingAmount.toStringAsFixed(0)} دج',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                pw.Spacer(),

                // ====== التوقيع ======
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Container(
                          width: 120,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.grey700),
                            ),
                          ),
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Center(
                            child: pw.Text(
                              'توقيع المستلم',
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
                        pw.SizedBox(height: 20),
                        pw.Container(
                          width: 120,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.grey700),
                            ),
                          ),
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Center(
                            child: pw.Text(
                              'ختم المؤسسة',
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

                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'شكراً لتعاملكم معنا',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// ✅ صف معلومات في PDF
  static pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _generatePdf(context);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _generatePdf(context);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'receipt_${payment.receiptNumber}.pdf',
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final group = groups.where((g) => g.id == payment.groupId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإيصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة',
            onPressed: _isGenerating ? null : () => _handlePrint(context),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'مشاركة',
            onPressed: _isGenerating ? null : () => _handleShare(context),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
        child: _ReceiptPreview(
          payment: payment,
          student: student,
          groupName: group?.name,
          receiptNumber: _formatReceiptNumber(),
          methodLabel: _methodLabel(payment.method),
        ),
      ),
      bottomNavigationBar: _ReceiptActionBar(
        isLoading: _isGenerating,
        onPrint: () => _handlePrint(context),
        onShare: () => _handleShare(context),
      ),
    );
  }
}

/// 🧾 معاينة الإيصال على الشاشة
class _ReceiptPreview extends StatelessWidget {
  final PaymentEntity payment;
  final StudentEntity student;
  final String? groupName;
  final String receiptNumber;
  final String methodLabel;

  const _ReceiptPreview({
    required this.payment,
    required this.student,
    required this.groupName,
    required this.receiptNumber,
    required this.methodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_Rad.card),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====== الرأس: العنوان + شارة رقم الإيصال ======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 18.sp,
                        color: colors.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'إيصال دفع',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Payment Receipt',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(_Rad.chip),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'رقم الإيصال',
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      receiptNumber,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _Sp.sm),

          // ====== التاريخ والوقت ======
          Row(
            children: [
              Icon(Icons.schedule, size: 13.sp, color: colors.onSurfaceVariant),
              SizedBox(width: 4.w),
              Text(
                '${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}  •  ${DateFormat('HH:mm').format(payment.paymentDate)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: _Sp.md),

          // ====== معلومات الطالب ======
          _InfoSection(
            icon: Icons.person_outline,
            title: 'معلومات الطالب',
            children: [
              _ReceiptRow(label: 'الاسم', value: student.fullName),
              _ReceiptRow(label: 'الرقم', value: student.studentCode),
              if (groupName != null)
                _ReceiptRow(label: 'الفوج', value: groupName!),
            ],
          ),
          SizedBox(height: _Sp.sm),

          // ====== تفاصيل الدفعة ======
          _InfoSection(
            icon: Icons.receipt_outlined,
            title: 'تفاصيل الدفعة',
            children: [
              _ReceiptRow(label: 'نوع الدفعة', value: payment.typeLabel),
              if (payment.monthYear != null)
                _ReceiptRow(label: 'الشهر', value: payment.monthYear!),
              _ReceiptRow(label: 'طريقة الدفع', value: methodLabel),
              if (payment.notes != null)
                _ReceiptRow(label: 'ملاحظات', value: payment.notes!),
            ],
          ),
          SizedBox(height: _Sp.sm),

          // ====== المبالغ — أبرز عنصر في الإيصال ======
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(_Rad.field),
              border: Border.all(color: colors.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _AmountRow(
                  label: 'المبلغ الإجمالي',
                  value: '${payment.originalAmount.toStringAsFixed(0)} دج',
                  color: colors.onSurfaceVariant,
                ),
                SizedBox(height: 8.h),
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withOpacity(0.6),
                ),
                SizedBox(height: 8.h),
                _AmountRow(
                  label: 'المبلغ المدفوع',
                  value: '${payment.amount.toStringAsFixed(0)} دج',
                  color: colors.primary,
                  isBold: true,
                  fontSize: 17,
                ),
                if (payment.remainingAmount > 0) ...[
                  SizedBox(height: 8.h),
                  _AmountRow(
                    label: 'المتبقي',
                    value: '${payment.remainingAmount.toStringAsFixed(0)} دج',
                    color: colors.error,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: _Sp.lg),

          // ====== التوقيع ======
          Row(
            children: [
              Expanded(
                child: _SignatureLine(label: 'توقيع المستلم', colors: colors),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: _SignatureLine(label: 'ختم المؤسسة', colors: colors),
              ),
            ],
          ),
          SizedBox(height: _Sp.sm),
          Center(
            child: Text(
              'شكراً لتعاملكم معنا',
              style: TextStyle(
                fontSize: 10.5.sp,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  final String label;
  final ColorScheme colors;
  const _SignatureLine({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 26.h),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.outlineVariant, width: 1),
            ),
          ),
          padding: EdgeInsets.only(top: 4.h),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

/// 📁 قسم معلومات — بطاقة تونالية بعنوان مصغّر وأيقونة
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_Rad.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: colors.primary),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ...children,
        ],
      ),
    );
  }
}

/// 📄 صف في الإيصال
class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 💰 صف المبلغ
class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;
  final double? fontSize;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: (fontSize ?? 12).sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: (fontSize ?? 12).sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 🔘 شريط الإجراءات السفلي الثابت — طباعة (أساسي) ومشاركة (ثانوي)
class _ReceiptActionBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _ReceiptActionBar({
    required this.isLoading,
    required this.onPrint,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onShare,
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: Text(
                      'مشاركة',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Rad.field),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48.h,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onPrint,
                    icon: isLoading
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: Text(
                      'طباعة الإيصال',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Rad.field),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

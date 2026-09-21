import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

import '../../../groups/presentation/bloc/groups_event.dart';

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
  static double get card => 20.r;
  static double get field => 12.r;
  static double get chip => 100.r;
}

/// 📁 صفحة بطاقة الطالب - معاينة + طباعة
class StudentCardPage extends StatefulWidget {
  final StudentEntity student;

  const StudentCardPage({super.key, required this.student});

  @override
  State<StudentCardPage> createState() => _StudentCardPageState();
}

class _StudentCardPageState extends State<StudentCardPage> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<GroupsBloc>().add(const FetchGroups());
    });
  }

  /// ✅ معلومات الطالب (للـ QR)
  String _generateQrData() {
    return 'STUDENT:${widget.student.id}|CODE:${widget.student.studentCode}';
  }

  /// ✅ تحميل خط عربي
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  List<String> _studentGroupNames() {
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];

    final studentEnrollments = enrollments
        .where((e) => e.studentId == widget.student.id && e.status == 'active')
        .toList();

    return groups
        .where((g) => studentEnrollments.any((e) => e.groupId == g.id))
        .map((g) => g.name)
        .toList();
  }

  /// ✅ توليد PDF البطاقة
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final studentGroups = _studentGroupNames();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 300,
              height: 480,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // ====== الرأس ======
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 16),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(12),
                        topRight: pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'بطاقة الطالب',
                          style: pw.TextStyle(
                            fontSize: 20,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'School Management System',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // ====== الصورة (دائرة بحرف) ======
                  pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey100,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.blue800, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        widget.student.firstName.isNotEmpty
                            ? widget.student.firstName.substring(0, 1)
                            : '؟',
                        style: pw.TextStyle(
                          fontSize: 40,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // ====== الاسم ======
                  pw.Text(
                    widget.student.fullName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 4),

                  // ====== الرقم ======
                  pw.Text(
                    'الرقم: ${widget.student.studentCode}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // ====== المعلومات ======
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                    child: pw.Column(
                      children: [
                        if (widget.student.dateOfBirth != null)
                          _pdfInfoRow(
                            'تاريخ الميلاد',
                            DateFormat(
                              'yyyy/MM/dd',
                            ).format(widget.student.dateOfBirth!),
                          ),
                        if (widget.student.gender != null)
                          _pdfInfoRow(
                            'الجنس',
                            widget.student.gender == 'male' ? 'ذكر' : 'أنثى',
                          ),
                        if (studentGroups.isNotEmpty)
                          _pdfInfoRow('الأفواج', studentGroups.join('، ')),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // ====== QR Code ======
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: _generateQrData(),
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  // ====== التذييل ======
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                      borderRadius: pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(12),
                        bottomRight: pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'هذه البطاقة ملك للمؤسسة - يُرجى إعادتها عند الطلب',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint() async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'student_${widget.student.studentCode}.pdf',
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقة الطالب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة',
            onPressed: _isGenerating ? null : _handlePrint,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'مشاركة',
            onPressed: _isGenerating ? null : _handleShare,
          ),
          SizedBox(width: 4.w),
        ],
      ),
      // ====== المحتوى: معاينة البطاقة فقط، والإجراءات في شريط سفلي ثابت ======
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
        child: Center(child: _buildCardPreview(context, colors)),
      ),
      bottomNavigationBar: _CardActionBar(
        isLoading: _isGenerating,
        onPrint: _handlePrint,
        onShare: _handleShare,
      ),
    );
  }

  /// ✅ معاينة البطاقة على الشاشة — بنمط بطاقة هوية رقمية Material 3
  Widget _buildCardPreview(BuildContext context, ColorScheme colors) {
    final studentGroups = _studentGroupNames();

    final infoRows = <MapEntry<String, String>>[
      if (widget.student.dateOfBirth != null)
        MapEntry(
          'تاريخ الميلاد',
          DateFormat('yyyy/MM/dd').format(widget.student.dateOfBirth!),
        ),
      if (widget.student.gender != null)
        MapEntry('الجنس', widget.student.gender == 'male' ? 'ذكر' : 'أنثى'),
      if (studentGroups.isNotEmpty)
        MapEntry('الأفواج', studentGroups.join('، ')),
    ];

    return Container(
      width: 300.w,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_Rad.card),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====== الرأس (Header Band) ======
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: _Sp.lg),
            color: colors.primary,
            child: Column(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: colors.onPrimary,
                  size: 22.sp,
                ),
                SizedBox(height: 4.h),
                Text(
                  'بطاقة الطالب',
                  style: TextStyle(
                    fontSize: 17.sp,
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'School Management System',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: colors.onPrimary.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, _Sp.lg, 20.w, _Sp.lg),
            child: Column(
              children: [
                // ====== الصورة الرمزية ======
                Container(
                  width: 76.w,
                  height: 76.w,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.student.firstName.isNotEmpty
                          ? widget.student.firstName.substring(0, 1)
                          : '؟',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _Sp.md),

                // ====== الاسم ورقم الطالب (كشارة) ======
                Text(
                  widget.student.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(_Rad.chip),
                  ),
                  child: Text(
                    widget.student.studentCode,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: colors.onSecondaryContainer,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                if (infoRows.isNotEmpty) ...[
                  SizedBox(height: _Sp.md),
                  // ====== لوحة المعلومات (Tonal Container) ======
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(_Rad.field),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < infoRows.length; i++) ...[
                          _InfoRow(
                            label: infoRows[i].key,
                            value: infoRows[i].value,
                          ),
                          if (i != infoRows.length - 1)
                            Divider(
                              height: 1,
                              color: colors.outlineVariant.withOpacity(0.5),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],

                SizedBox(height: _Sp.lg),

                // ====== QR Code داخل لوحة بيضاء بارزة ======
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_Rad.field),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: QrImageView(
                    data: _generateQrData(),
                    version: QrVersions.auto,
                    size: 92.w,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ====== التذييل ======
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 9.h),
            color: colors.primary,
            child: Center(
              child: Text(
                'هذه البطاقة ملك للمؤسسة',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: colors.onPrimary.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🧾 صف معلومات داخل لوحة البطاقة
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
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

/// 🔘 شريط الإجراءات السفلي الثابت — طباعة (أساسي) ومشاركة (ثانوي)
class _CardActionBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _CardActionBar({
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
                      'طباعة البطاقة',
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

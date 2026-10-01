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
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';

import '../../../students/presentation/bloc/students_event.dart';
import '../../../students/presentation/bloc/students_state.dart';
import '../bloc/groups_bloc.dart';

// ثوابت
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 تقرير الفوج الشامل
class GroupFullReportPage extends StatefulWidget {
  final GroupEntity group;

  const GroupFullReportPage({super.key, required this.group});

  @override
  State<GroupFullReportPage> createState() => _GroupFullReportPageState();
}

class _GroupFullReportPageState extends State<GroupFullReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<FinanceBloc>().add(FetchAllFinanceData());
      context.read<AttendanceBloc>().add(FetchTodaySessions());
    });
  }

  /// ✅ تحميل الخط
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ توليد PDF
  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final now = DateTime.now();

    // جلب البيانات
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final payments = context.read<FinanceBloc>().state.paymentsState.data ?? [];
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final subjects =
        context.read<SubjectsBloc>().state.subjectsState.data ?? [];
    final teachers =
        context.read<TeachersBloc>().state.teachersState.data ?? [];
    final grades = context.read<GradesBloc>().state.gradesState.data ?? [];

    // الطلاب المسجلين في هذا الفوج
    final groupEnrollments = enrollments
        .where((e) => e.groupId == widget.group.id && e.status == 'active')
        .toList();

    final groupStudentIds = groupEnrollments.map((e) => e.studentId).toSet();
    final groupStudents = students
        .where((s) => groupStudentIds.contains(s.id))
        .toList();

    // معلومات إضافية
    final subject = subjects
        .where((s) => s.id == widget.group.subjectId)
        .firstOrNull;
    final teacher = teachers
        .where((t) => t.id == widget.group.teacherId)
        .firstOrNull;
    final grade = grades.where((g) => g.id == widget.group.gradeId).firstOrNull;

    // حسابات الحضور
    final sessionIds =
        (context.read<AttendanceBloc>().state.sessionsState.data ?? [])
            .where((s) => s.groupId == widget.group.id)
            .map((s) => s.id)
            .toSet();

    // المالية
    final groupPayments = payments
        .where((p) => p.groupId == widget.group.id)
        .toList();

    final totalPaid = groupPayments
        .where((p) => p.type != 'exemption' && p.type != 'extra_payment')
        .fold<double>(0, (sum, p) => sum + p.amount);

    final totalRemaining = groupPayments
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
              padding: const pw.EdgeInsets.all(14),
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
                        'تقرير الفوج الشامل',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Group Comprehensive Report',
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
                        'تاريخ: ${DateFormat('yyyy/MM/dd').format(now)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'الوقت: ${DateFormat('HH:mm').format(now)}',
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

            // ====== معلومات الفوج ======
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'معلومات الفوج',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfInfoRow('اسم الفوج', widget.group.name),
                            _pdfInfoRow('الصف', grade?.name ?? '-'),
                            _pdfInfoRow('المادة', subject?.name ?? '-'),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfInfoRow('المعلم', teacher?.fullName ?? '-'),
                            _pdfInfoRow(
                              'الرسوم الشهرية',
                              '${widget.group.monthlyFee.toStringAsFixed(0)} دج',
                            ),
                            _pdfInfoRow(
                              'عدد الطلاب',
                              '${groupStudents.length} / ${widget.group.maxStudents}',
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

            // ====== الملخص المالي ======
            pw.Text(
              'الملخص المالي',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _pdfSummaryRow(
                    'إجمالي الإيرادات',
                    '${totalPaid.toStringAsFixed(0)} دج',
                    PdfColors.green800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    'إجمالي المتأخرات',
                    '${totalRemaining.toStringAsFixed(0)} دج',
                    totalRemaining > 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ====== جدول الطلاب ======
            pw.Text(
              'قائمة الطلاب',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),

            if (groupStudents.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'لا يوجد طلاب مسجلون',
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
                  0: const pw.FlexColumnWidth(0.4),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.3),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _pdfTableHeader('#'),
                      _pdfTableHeader('الطالب'),
                      _pdfTableHeader('الرقم'),
                      _pdfTableHeader('المدفوع'),
                      _pdfTableHeader('المتبقي'),
                    ],
                  ),
                  ...groupStudents.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final s = entry.value;

                    // دفعات هذا الطالب في هذا الفوج
                    final sPayments = groupPayments.where(
                      (p) => p.studentId == s.id,
                    );
                    final sPaid = sPayments
                        .where(
                          (p) =>
                              p.type != 'exemption' &&
                              p.type != 'extra_payment',
                        )
                        .fold<double>(0, (sum, p) => sum + p.amount);
                    final sRemaining = sPayments
                        .where(
                          (p) =>
                              p.remainingAmount > 0 &&
                              p.type != 'extra_payment',
                        )
                        .fold<double>(0, (sum, p) => sum + p.remainingAmount);

                    return pw.TableRow(
                      children: [
                        _pdfTableCell('$i'),
                        _pdfTableCell(s.fullName, align: pw.TextAlign.right),
                        _pdfTableCell(s.studentCode),
                        _pdfTableCell(
                          '${sPaid.toStringAsFixed(0)} دج',
                          color: PdfColors.green800,
                        ),
                        _pdfTableCell(
                          sRemaining > 0
                              ? '${sRemaining.toStringAsFixed(0)} دج'
                              : '-',
                          color: sRemaining > 0
                              ? PdfColors.red800
                              : PdfColors.grey600,
                        ),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 24),

            // ====== التوقيع ======
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
                          'توقيع المدير',
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
          ];
        },
      ),
    );

    return pdf.save();
  }

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('تقرير شامل: ${widget.group.name}')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<StudentsBloc, StudentsState>(
            listener: (_, __) => setState(() {}),
          ),
          BlocListener<EnrollmentBloc, EnrollmentState>(
            listener: (_, __) => setState(() {}),
          ),
          BlocListener<FinanceBloc, FinanceState>(
            listener: (_, __) => setState(() {}),
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: _buildPreview(context, colors),
              ),
            ),
            // الشريط السفلي
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
                            final pdfBytes = await _generatePdf(context);
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
                            final pdfBytes = await _generatePdf(context);
                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename: 'group_report_${widget.group.id}.pdf',
                            );
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text(
                            'مشاركة',
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
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ColorScheme colors) {
    return BlocBuilder<StudentsBloc, StudentsState>(
      builder: (context, studentsState) {
        return BlocBuilder<EnrollmentBloc, EnrollmentState>(
          builder: (context, enrollmentState) {
            return BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, financeState) {
                final students = studentsState.studentsState.data ?? [];
                final enrollments = enrollmentState.enrollmentsState.data ?? [];
                final payments = financeState.paymentsState.data ?? [];

                final groupEnrollments = enrollments
                    .where(
                      (e) =>
                          e.groupId == widget.group.id && e.status == 'active',
                    )
                    .toList();
                final studentIds = groupEnrollments
                    .map((e) => e.studentId)
                    .toSet();
                final groupStudents = students
                    .where((s) => studentIds.contains(s.id))
                    .toList();

                final groupPayments = payments
                    .where((p) => p.groupId == widget.group.id)
                    .toList();
                final totalPaid = groupPayments
                    .where(
                      (p) => p.type != 'exemption' && p.type != 'extra_payment',
                    )
                    .fold<double>(0, (sum, p) => sum + p.amount);
                final totalRemaining = groupPayments
                    .where(
                      (p) => p.remainingAmount > 0 && p.type != 'extra_payment',
                    )
                    .fold<double>(0, (sum, p) => sum + p.remainingAmount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بطاقة الفوج
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.secondary,
                            colors.secondary.withOpacity(0.8),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(_kRadius),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.groups, size: 40.sp, color: Colors.white),
                          SizedBox(height: 8.h),
                          Text(
                            widget.group.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${groupStudents.length} طالب • ${widget.group.monthlyFee.toStringAsFixed(0)} دج',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: _Gap.md),

                    // الملخص المالي
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'الإيرادات',
                            value: '${totalPaid.toStringAsFixed(0)} دج',
                            color: colors.secondary,
                            icon: Icons.trending_up,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _SummaryCard(
                            label: 'المتأخرات',
                            value: '${totalRemaining.toStringAsFixed(0)} دج',
                            color: totalRemaining > 0
                                ? colors.error
                                : colors.secondary,
                            icon: Icons.warning_amber,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _Gap.md),

                    // جدول الطلاب
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16.sp,
                                  color: colors.primary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'قائمة الطلاب',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            if (groupStudents.isEmpty)
                              Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Text(
                                  'لا يوجد طلاب',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else
                              ...groupStudents.map((s) {
                                final sPayments = groupPayments.where(
                                  (p) => p.studentId == s.id,
                                );
                                final sPaid = sPayments
                                    .where(
                                      (p) =>
                                          p.type != 'exemption' &&
                                          p.type != 'extra_payment',
                                    )
                                    .fold<double>(
                                      0,
                                      (sum, p) => sum + p.amount,
                                    );
                                final sRemaining = sPayments
                                    .where(
                                      (p) =>
                                          p.remainingAmount > 0 &&
                                          p.type != 'extra_payment',
                                    )
                                    .fold<double>(
                                      0,
                                      (sum, p) => sum + p.remainingAmount,
                                    );

                                return Container(
                                  margin: EdgeInsets.only(bottom: 4.h),
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.fullName,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${sPaid.toStringAsFixed(0)} دج',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: colors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          sRemaining > 0
                                              ? '${sRemaining.toStringAsFixed(0)} دج'
                                              : '-',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: sRemaining > 0
                                                ? colors.error
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

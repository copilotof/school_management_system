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
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import '../../../../core/states/ui_state.dart';
import '../../../students/presentation/bloc/students_state.dart';

// ثوابت
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة تقرير الحضور
class AttendanceReportPage extends StatefulWidget {
  final GroupEntity group;
  final StudentEntity? student; // null = تقرير فوج

  const AttendanceReportPage({super.key, required this.group, this.student});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // الافتراضي: الشهر الحالي
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
    _loadReport();
  }

  void _loadReport() {
    setState(() => _isLoading = true);
    final bloc = context.read<AttendanceBloc>();

    if (widget.student != null) {
      bloc.add(
        FetchAttendanceReportForStudent(
          studentId: widget.student!.id!,
          groupId: widget.group.id!,
          from: _fromDate,
          to: _toDate,
        ),
      );
    } else {
      bloc.add(
        FetchAttendanceReportForGroup(
          groupId: widget.group.id!,
          from: _fromDate,
          to: _toDate,
        ),
      );
    }
    setState(() => _isLoading = false);
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
      _loadReport();
    }
  }

  /// ✅ تحميل الخط
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ توليد PDF
  Future<Uint8List> _generatePdf(
    BuildContext context,
    List<AttendanceEntity> attendance,
  ) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final now = DateTime.now();

    // ✅ حسابات عامة
    final present = attendance.where((a) => a.status == 'present').length;
    final absent = attendance.where((a) => a.status == 'absent').length;
    final late = attendance.where((a) => a.status == 'late').length;
    final total = attendance.length;
    final attendanceRate = total > 0 ? (present / total * 100) : 0.0;

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
                        context.tr('reports.attendanceReport'),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        widget.student != null
                            ? context.tr('reports.studentReport')
                            : context.tr('reports.groupReport'),
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
                        '${context.tr('reports.fromDate')}: ${context.formatDate(_fromDate)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${context.tr('reports.toDate')}: ${context.formatDate(_toDate)}',
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

            // ====== معلومات ======
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (widget.student != null)
                    _pdfInfoRow(
                      context.tr('reports.studentLabel'),
                      widget.student!.fullName,
                    ),
                  if (widget.student != null)
                    _pdfInfoRow(
                      context.tr('reports.codeLabel'),
                      widget.student!.studentCode,
                    ),
                  _pdfInfoRow(
                    context.tr('reports.groupLabel'),
                    widget.group.name,
                  ),
                  _pdfInfoRow(
                    context.tr('reports.dateRange'),
                    '${DateFormat('yyyy/MM/dd').format(_fromDate)} - ${DateFormat('yyyy/MM/dd').format(_toDate)}',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ====== الملخص ======
            pw.Text(
              context.tr('reports.summary'),
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
                    context.tr('reports.totalSessions'),
                    '$total',
                    PdfColors.blue800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    context.tr('reports.presentCount'),
                    '$present',
                    PdfColors.green800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    context.tr('reports.absentCount'),
                    '$absent',
                    PdfColors.red800,
                  ),
                  pw.SizedBox(height: 4),
                  _pdfSummaryRow(
                    context.tr('reports.lateCount'),
                    '$late',
                    PdfColors.orange800,
                  ),
                  pw.Divider(color: PdfColors.blue800),
                  _pdfSummaryRow(
                    context.tr('reports.attendanceRate'),
                    '${attendanceRate.toStringAsFixed(1)}%',
                    attendanceRate >= 75
                        ? PdfColors.green800
                        : PdfColors.red800,
                    isBold: true,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ====== التفاصيل (حسب نوع التقرير) ======
            pw.Text(
              widget.student != null
                  ? context.tr('reports.attendanceLog')
                  : context.tr('reports.homeworkStats'),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),

            if (attendance.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  context.tr('reports.noDataPeriod'),
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              )
            else if (widget.student != null)
              // ✅ تقرير طالب: جدول الحضور الفردي
              _buildStudentPdfTable(attendance)
            else
              // ✅ تقرير فوج: جدول إحصائيات الطلاب
              _buildGroupPdfTable(context, attendance),

            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                '${context.tr('reports.printDate')}: ${context.formatDateTime(now)}',
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

  /// ✅ جدول PDF لتقرير الطالب (سجل الحضور الفردي)
  pw.Widget _buildStudentPdfTable(List<AttendanceEntity> attendance) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _pdfTableHeader('#'),
            _pdfTableHeader(context.tr('common.date')),
            _pdfTableHeader(context.tr('reports.statusLabel')),
          ],
        ),
        ...attendance.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final a = entry.value;
          return pw.TableRow(
            children: [
              _pdfTableCell('$index'),
              _pdfTableCell(
                DateFormat(
                  'yyyy/MM/dd',
                ).format(a.checkInTime ?? a.createdAt ?? DateTime.now()),
              ),
              _pdfTableCell(
                context.tr(a.statusKey),
                color: a.status == 'present'
                    ? PdfColors.green800
                    : a.status == 'absent'
                    ? PdfColors.red800
                    : PdfColors.orange800,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// ✅ جدول PDF لتقرير الفوج (إحصائيات كل طالب)
  pw.Widget _buildGroupPdfTable(
    BuildContext context,
    List<AttendanceEntity> attendance,
  ) {
    // جلب طلاب الفوج
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];

    final groupStudentIds = enrollments
        .where((e) => e.groupId == widget.group.id && e.status == 'active')
        .map((e) => e.studentId)
        .toSet();

    final groupStudents = students
        .where((s) => groupStudentIds.contains(s.id))
        .toList();

    // إنشاء صفوف الجدول
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        children: [
          _pdfTableHeader('#'),
          _pdfTableHeader(context.tr('reports.studentLabel')),
          _pdfTableHeader(context.tr('reports.codeLabel')),
          _pdfTableHeader(context.tr('reports.presentCount')),
          _pdfTableHeader(context.tr('reports.absentCount')),
          _pdfTableHeader(context.tr('reports.lateCount')),
          _pdfTableHeader(context.tr('reports.rateLabel')),
        ],
      ),
    ];

    for (var i = 0; i < groupStudents.length; i++) {
      final s = groupStudents[i];
      final studentAttendance = attendance
          .where((a) => a.studentId == s.id)
          .toList();
      final sPresent = studentAttendance
          .where((a) => a.status == 'present')
          .length;
      final sAbsent = studentAttendance
          .where((a) => a.status == 'absent')
          .length;
      final sLate = studentAttendance.where((a) => a.status == 'late').length;
      final sTotal = studentAttendance.length;
      final sRate = sTotal > 0 ? (sPresent / sTotal * 100) : 0.0;

      rows.add(
        pw.TableRow(
          children: [
            _pdfTableCell('${i + 1}'),
            _pdfTableCell(s.fullName, align: pw.TextAlign.right),
            _pdfTableCell(s.studentCode),
            _pdfTableCell('$sPresent', color: PdfColors.green800),
            _pdfTableCell('$sAbsent', color: PdfColors.red800),
            _pdfTableCell('$sLate', color: PdfColors.orange800),
            _pdfTableCell(
              '${sRate.toStringAsFixed(0)}%',
              color: sRate >= 75 ? PdfColors.green800 : PdfColors.red800,
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
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
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: color),
        textAlign: align,
      ),
    );
  }

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
            fontSize: isBold ? 12 : 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? 13 : 10,
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
      appBar: AppBar(
        title: Text(
          widget.student != null
              ? '${context.tr('reports.attendanceReport')}: ${widget.student!.fullName}'
              : '${context.tr('reports.attendanceReport')}: ${widget.group.name}',
        ),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final attendance = state.reportState.data ?? [];

          return Column(
            children: [
              // ====== فلترة التاريخ ======
              Container(
                margin: EdgeInsets.all(12.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(
                    color: colors.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.tr('reports.fromDate'),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                            ),
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
                          decoration: InputDecoration(
                            labelText: context.tr('reports.toDate'),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                            ),
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
              ),

              // ====== المحتوى ======
              Expanded(
                child: switch (state.reportState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64.sp,
                          color: colors.onSurfaceVariant,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          context.tr('reports.noDataPeriod'),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Error(message: final msg) => Center(child: Text(msg)),
                  Success(data: final attendance) => _buildReportContent(
                    attendance,
                    colors,
                  ),
                },
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
                                attendance,
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
                                attendance,
                              );
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename:
                                    'attendance_report_${widget.group.id}.pdf',
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

  Widget _buildReportContent(
    List<AttendanceEntity> attendance,
    ColorScheme colors,
  ) {
    // حسابات
    final present = attendance.where((a) => a.status == 'present').length;
    final absent = attendance.where((a) => a.status == 'absent').length;
    final late = attendance.where((a) => a.status == 'late').length;
    final total = attendance.length;
    final attendanceRate = total > 0 ? (present / total * 100) : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الملخص
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: context.tr('common.all'),
                  value: '$total',
                  color: colors.primary,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _StatBox(
                  label: context.tr('reports.presentCount'),
                  value: '$present',
                  color: colors.secondary,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _StatBox(
                  label: context.tr('reports.absentCount'),
                  value: '$absent',
                  color: colors.error,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _StatBox(
                  label: context.tr('reports.lateCount'),
                  value: '$late',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // نسبة الحضور
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: attendanceRate >= 75
                  ? colors.secondary.withOpacity(0.1)
                  : colors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: attendanceRate >= 75 ? colors.secondary : colors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  attendanceRate >= 75
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: attendanceRate >= 75 ? colors.secondary : colors.error,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${context.tr('reports.attendanceRate')}:',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: attendanceRate >= 75
                        ? colors.secondary
                        : colors.error,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // التفاصيل
          if (widget.student == null) ...[
            // تقرير فوج: قائمة الطلاب
            _buildGroupDetails(attendance, colors),
          ] else ...[
            // تقرير طالب: سجل الحضور
            _buildStudentDetails(attendance, colors),
          ],
        ],
      ),
    );
  }

  /// ✅ تفاصيل الفوج (كل طالب + إحصائياته)
  Widget _buildGroupDetails(
    List<AttendanceEntity> attendance,
    ColorScheme colors,
  ) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, enrollmentState) {
        return BlocBuilder<StudentsBloc, StudentsState>(
          builder: (context, studentsState) {
            final enrollments = enrollmentState.enrollmentsState.data ?? [];
            final students = studentsState.studentsState.data ?? [];

            final groupStudentIds = enrollments
                .where(
                  (e) => e.groupId == widget.group.id && e.status == 'active',
                )
                .map((e) => e.studentId)
                .toSet();

            final groupStudents = students
                .where((s) => groupStudentIds.contains(s.id))
                .toList();

            return Card(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('reports.homeworkStats'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...groupStudents.map((s) {
                      final studentAttendance = attendance
                          .where((a) => a.studentId == s.id)
                          .toList();
                      final sPresent = studentAttendance
                          .where((a) => a.status == 'present')
                          .length;
                      final sAbsent = studentAttendance
                          .where((a) => a.status == 'absent')
                          .length;
                      final sLate = studentAttendance
                          .where((a) => a.status == 'late')
                          .length;
                      final sTotal = studentAttendance.length;
                      final sRate = sTotal > 0
                          ? (sPresent / sTotal * 100)
                          : 0.0;

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
                                '${context.tr('reports.presentShort')}: $sPresent',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: colors.secondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${context.tr('reports.absentShort')}: $sAbsent',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: colors.error,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${context.tr('reports.lateShort')}: $sLate',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            Text(
                              '${sRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: sRate >= 75
                                    ? colors.secondary
                                    : colors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ تفاصيل الطالب (سجل الحضور)
  Widget _buildStudentDetails(
    List<AttendanceEntity> attendance,
    ColorScheme colors,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('reports.attendanceLog'),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            SizedBox(height: 8.h),
            ...attendance.map((a) {
              final (color, icon, label) = switch (a.status) {
                'present' => (
                  colors.secondary,
                  Icons.check_circle,
                  context.tr('reports.presentCount'),
                ),
                'absent' => (
                  colors.error,
                  Icons.cancel,
                  context.tr('reports.absentCount'),
                ),
                'late' => (
                  colors.primary,
                  Icons.timelapse,
                  context.tr('reports.lateCount'),
                ),
                _ => (colors.onSurfaceVariant, Icons.help, a.status),
              };

              return Container(
                margin: EdgeInsets.only(bottom: 4.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 14.sp, color: color),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        DateFormat('yyyy/MM/dd').format(
                          a.checkInTime ?? a.createdAt ?? DateTime.now(),
                        ),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 📊 صندوق إحصائي
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

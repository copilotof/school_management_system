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
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';
import 'package:school_management_system/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import '../../../../core/utils/translation_extension.dart';
import '../../../students/presentation/bloc/students_state.dart';

class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة تقرير الواجبات
class HomeworkReportPage extends StatefulWidget {
  final GroupEntity group;

  const HomeworkReportPage({super.key, required this.group});

  @override
  State<HomeworkReportPage> createState() => _HomeworkReportPageState();
}

class _HomeworkReportPageState extends State<HomeworkReportPage> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
    _loadReport();
  }

  void _loadReport() {
    context.read<HomeworkBloc>().add(
      FetchHomeworksReport(
        groupId: widget.group.id!,
        from: _fromDate,
        to: _toDate,
      ),
    );
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

  /// ✅ توليد PDF لكل الواجبات
  Future<Uint8List> _generatePdf(List<HomeworkEntity> homeworks) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final now = DateTime.now();

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
                        'تقرير الواجبات',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Homework Report',
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

            // المعلومات
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfInfoRow('الفوج', widget.group.name),
                  _pdfInfoRow('عدد الواجبات', '${homeworks.length}'),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // جدول الواجبات
            if (homeworks.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'لا توجد واجبات في هذه الفترة',
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
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _pdfTableHeader('#'),
                      _pdfTableHeader('عنوان الواجب'),
                      _pdfTableHeader('تاريخ التسليم'),
                      _pdfTableHeader('سلّم'),
                      _pdfTableHeader('لم يسلّم'),
                      _pdfTableHeader('متأخر'),
                    ],
                  ),
                  ...homeworks.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final hw = entry.value;
                    // ملاحظة: الإحصائيات هنا ستُحسب لاحقاً
                    return pw.TableRow(
                      children: [
                        _pdfTableCell('$i'),
                        _pdfTableCell(hw.title, align: pw.TextAlign.right),
                        _pdfTableCell(
                          DateFormat('yyyy/MM/dd').format(hw.dueDate),
                        ),
                        _pdfTableCell('—'),
                        _pdfTableCell('—'),
                        _pdfTableCell('—'),
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
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: align,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${context.tr('homework.reportTitle')}: ${widget.group.name}',
        ),
      ),
      body: BlocBuilder<HomeworkBloc, HomeworkState>(
        builder: (context, state) {
          final homeworks = state.homeworksState.data ?? [];

          return Column(
            children: [
              // فلترة
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

              // المحتوى
              Expanded(
                child: switch (state.homeworksState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64.sp,
                          color: colors.onSurfaceVariant,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          context.tr('homework.noHomeworksPeriod'),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Error(message: final msg) => Center(child: Text(msg)),
                  Success(data: final homeworks) => ListView.builder(
                    padding: EdgeInsets.all(12.w),
                    itemCount: homeworks.length,
                    itemBuilder: (context, index) {
                      return _HomeworkReportCard(homework: homeworks[index]);
                    },
                  ),
                },
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
                              final pdfBytes = await _generatePdf(homeworks);
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
                              final pdfBytes = await _generatePdf(homeworks);
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename:
                                    'homework_report_${widget.group.id}.pdf',
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
          );
        },
      ),
    );
  }
}

/// 📁 بطاقة تقرير واجب واحد
class _HomeworkReportCard extends StatelessWidget {
  final HomeworkEntity homework;

  const _HomeworkReportCard({required this.homework});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final homeworkBloc = context.read<HomeworkBloc>();

    // ✅ تحميل التسليمات
    homeworkBloc.add(FetchSubmissions(homework.id!));

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, size: 18.sp, color: colors.primary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    homework.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18.sp,
                    color: colors.primary,
                  ),
                  tooltip: context.tr('homework.submissions'),
                  onPressed: () {
                    _showSubmissionsDialog(context, homework, homeworkBloc);
                  },
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              homework.description,
              style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12.sp,
                  color: colors.onSurfaceVariant,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${context.tr('homework.dueDate')}: ${DateFormat('yyyy/MM/dd').format(homework.dueDate)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ نافذة التسليمات
  void _showSubmissionsDialog(
    BuildContext context,
    HomeworkEntity homework,
    HomeworkBloc homeworkBloc,
  ) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: homeworkBloc,
        child: _SubmissionsDialog(homework: homework),
      ),
    );
  }
}

/// 📁 نافذة عرض التسليمات
class _SubmissionsDialog extends StatefulWidget {
  final HomeworkEntity homework;

  const _SubmissionsDialog({required this.homework});

  @override
  State<_SubmissionsDialog> createState() => _SubmissionsDialogState();
}

class _SubmissionsDialogState extends State<_SubmissionsDialog> {
  @override
  void initState() {
    super.initState();
    context.read<HomeworkBloc>().add(FetchSubmissions(widget.homework.id!));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الرأس
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: colors.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.homework.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),

            // التسليمات
            Flexible(
              child: BlocBuilder<HomeworkBloc, HomeworkState>(
                builder: (context, state) {
                  return switch (state.submissionsState) {
                    Initial() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    Loading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    Empty() => const Center(child: Text('لا توجد تسليمات')),
                    Error(message: final msg) => Center(child: Text(msg)),
                    Success(data: final submissions) => _buildList(
                      context,
                      submissions,
                      colors,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<HomeworkSubmissionEntity> submissions,
    ColorScheme colors,
  ) {
    return BlocBuilder<StudentsBloc, StudentsState>(
      builder: (context, studentsState) {
        final students = studentsState.studentsState.data ?? [];

        // إحصائيات
        final submitted = submissions
            .where((s) => s.status == 'submitted')
            .length;
        final late = submissions.where((s) => s.status == 'late').length;
        final missing = submissions.where((s) => s.status == 'missing').length;

        return Column(
          children: [
            // الإحصائيات
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: context.tr('homework.submitted'),
                      value: '$submitted',
                      color: colors.secondary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _MiniStat(
                      label: context.tr('homework.late'),
                      value: '$late',
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _MiniStat(
                      label: context.tr('homework.missing'),
                      value: '$missing',
                      color: colors.error,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            // القائمة
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  final student = students
                      .where((s) => s.id == submission.studentId)
                      .firstOrNull;
                  if (student == null) return const SizedBox.shrink();

                  return _SubmissionRow(
                    submission: submission,
                    student: student,
                    onStatusChanged: (status) {
                      final updated = submission.copyWith(
                        status: status,
                        submittedAt: status == 'submitted' || status == 'late'
                            ? DateTime.now()
                            : null,
                      );
                      context.read<HomeworkBloc>().add(
                        UpdateSubmissionEvent(updated),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 📊 إحصائية صغيرة
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
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

/// 📄 صف تسليم طالب
class _SubmissionRow extends StatelessWidget {
  final HomeworkSubmissionEntity submission;
  final StudentEntity student;
  final ValueChanged<String> onStatusChanged;

  const _SubmissionRow({
    required this.submission,
    required this.student,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (statusColor, statusIcon, statusLabel) = switch (submission.status) {
      'submitted' => (
        colors.secondary,
        Icons.check_circle,
        context.tr('homework.submitted'),
      ),
      'late' => (colors.primary, Icons.timelapse, context.tr('homework.late')),
      'missing' => (colors.error, Icons.cancel, context.tr('homework.missing')),
      _ => (
        colors.onSurfaceVariant,
        Icons.pending_outlined,
        context.tr('homework.pending'),
      ),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14.r,
            backgroundColor: colors.primaryContainer,
            child: Text(
              student.firstName.isNotEmpty
                  ? student.firstName.substring(0, 1)
                  : '؟',
              style: TextStyle(
                fontSize: 11.sp,
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              student.fullName,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(statusIcon, size: 14.sp, color: statusColor),
          SizedBox(width: 4.w),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11.sp,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

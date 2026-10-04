import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import '../../../groups/presentation/bloc/groups_event.dart';
import '../../../groups/presentation/bloc/groups_state.dart';
import '../bloc/students_event.dart';
import '../bloc/students_state.dart';

class _Gap {
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة طباعة QR لجميع الطلاب
class StudentsQrPrintPage extends StatefulWidget {
  const StudentsQrPrintPage({super.key});

  @override
  State<StudentsQrPrintPage> createState() => _StudentsQrPrintPageState();
}

class _StudentsQrPrintPageState extends State<StudentsQrPrintPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<GroupsBloc>().add(const FetchGroups());
    });
  }

  /// ✅ تنسيق بيانات QR
  String _generateQrData(StudentEntity student) {
    return 'STUDENT:${student.id}|CODE:${student.studentCode}';
  }

  /// ✅ تحميل الخط
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  }

  /// ✅ تجميع الطلاب حسب الفوج
  Map<String, List<StudentEntity>> _groupStudentsByGroup(
    List<StudentEntity> students,
    List<dynamic> enrollments,
    List<dynamic> groups,
  ) {
    final result = <String, List<StudentEntity>>{};

    for (final group in groups) {
      final studentIds = enrollments
          .where((e) => e.groupId == group.id && e.status == 'active')
          .map((e) => e.studentId)
          .toSet();

      final groupStudents =
          students.where((s) => studentIds.contains(s.id)).toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

      if (groupStudents.isNotEmpty) {
        result[group.name] = groupStudents;
      }
    }

    return result;
  }

  /// ✅ توليد PDF
  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    // جلب البيانات
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];

    final groupedStudents = _groupStudentsByGroup(
      students,
      enrollments,
      groups,
    );

    // ✅ عدد QR في كل صف
    const qrPerRow = 3;
    // ✅ عدد الصفوف في كل صفحة
    const rowsPerPage = 4;
    // ✅ عدد QR في الصفحة
    const qrPerPage = qrPerRow * rowsPerPage;

    for (final entry in groupedStudents.entries) {
      final groupName = entry.key;
      final groupStudents = entry.value;

      // تقسيم الطلاب إلى صفحات
      for (var i = 0; i < groupStudents.length; i += qrPerPage) {
        final pageStudents = groupStudents.skip(i).take(qrPerPage).toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // رأس الفوج (يظهر في كل صفحة)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue800,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'رموز QR - $groupName',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'الصفحة ${(i ~/ qrPerPage) + 1} من ${(groupStudents.length / qrPerPage).ceil()}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // الشبكة
                  ...List.generate(rowsPerPage, (rowIndex) {
                    final rowStart = rowIndex * qrPerRow;
                    if (rowStart >= pageStudents.length) {
                      return pw.SizedBox.shrink();
                    }
                    final rowStudents = pageStudents
                        .skip(rowStart)
                        .take(qrPerRow)
                        .toList();

                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 16),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: List.generate(qrPerRow, (colIndex) {
                          if (colIndex >= rowStudents.length) {
                            return pw.SizedBox(width: 150, height: 180);
                          }

                          final student = rowStudents[colIndex];
                          return _buildQrCard(student);
                        }),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      }
    }

    // إذا لا يوجد طلاب
    if (groupedStudents.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Text(
                'لا يوجد طلاب مسجلون في أي فوج',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// ✅ بطاقة QR لطالب
  pw.Widget _buildQrCard(StudentEntity student) {
    return pw.Container(
      width: 150,
      height: 180,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // QR Code
          pw.Container(
            width: 100,
            height: 100,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: _generateQrData(student),
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 8),
          // اسم الطالب
          pw.Text(
            student.fullName,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
          pw.SizedBox(height: 2),
          // رقم الطالب
          pw.Text(
            student.studentCode,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('طباعة رموز QR')),
      body: BlocBuilder<StudentsBloc, StudentsState>(
        builder: (context, studentsState) {
          return BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, enrollmentState) {
              return BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, groupsState) {
                  final students = studentsState.studentsState.data ?? [];
                  final enrollments =
                      enrollmentState.enrollmentsState.data ?? [];
                  final groups = groupsState.groupsState.data ?? [];

                  final groupedStudents = _groupStudentsByGroup(
                    students,
                    enrollments,
                    groups,
                  );

                  if (groupedStudents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 64.sp,
                            color: colors.onSurfaceVariant,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'لا يوجد طلاب مسجلون',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // معاينة على الشاشة
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // إحصائيات
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer.withOpacity(
                                    0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(_kRadius),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      color: colors.primary,
                                      size: 24.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${students.length} طالب',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${groupedStudents.length} فوج • ${groupedStudents.values.fold<int>(0, (sum, list) => sum + list.length)} رمز QR',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: _Gap.md),

                              // معاينة لكل فوج
                              ...groupedStudents.entries.map((entry) {
                                return _GroupQrPreview(
                                  groupName: entry.key,
                                  students: entry.value,
                                  qrDataGenerator: _generateQrData,
                                );
                              }),
                            ],
                          ),
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
                                      final pdfBytes = await _generatePdf(
                                        context,
                                      );
                                      await Printing.layoutPdf(
                                        onLayout: (format) async => pdfBytes,
                                      );
                                    },
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('طباعة الكل'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          _kRadius,
                                        ),
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
                                      );
                                      await Printing.sharePdf(
                                        bytes: pdfBytes,
                                        filename: 'students_qr_codes.pdf',
                                      );
                                    },
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text(
                                      'مشاركة',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          _kRadius,
                                        ),
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
              );
            },
          );
        },
      ),
    );
  }
}

/// 📁 معاينة QR لفوج
class _GroupQrPreview extends StatelessWidget {
  final String groupName;
  final List<StudentEntity> students;
  final String Function(StudentEntity) qrDataGenerator;

  const _GroupQrPreview({
    required this.groupName,
    required this.students,
    required this.qrDataGenerator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس الفوج
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    size: 16.sp,
                    color: colors.onPrimaryContainer,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    '${students.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // شبكة QR
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _QrPreviewCard(
                  student: student,
                  qrData: qrDataGenerator(student),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 بطاقة معاينة QR
class _QrPreviewCard extends StatelessWidget {
  final StudentEntity student;
  final String qrData;

  const _QrPreviewCard({required this.student, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR
          Flexible(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          SizedBox(height: 4.h),
          // اسم الطالب
          Text(
            student.fullName,
            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            student.studentCode,
            style: TextStyle(fontSize: 8.sp, color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

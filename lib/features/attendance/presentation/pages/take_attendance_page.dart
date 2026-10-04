import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';

import '../../../groups/presentation/bloc/groups_event.dart';
import '../../../homework/domain/entities/homework_entity.dart';
import '../../../homework/presentation/bloc/homework_bloc.dart';
import '../../../homework/presentation/widgets/add_homework_dialog.dart';
import '../../../homework/presentation/widgets/homework_submissions_dialog.dart';
import '../../../students/presentation/bloc/students_state.dart';
import 'qr_scanner_page.dart';

// ثوابت التصميم
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة تسجيل الحضور
class TakeAttendancePage extends StatefulWidget {
  final SessionEntity session;
  const TakeAttendancePage({super.key, required this.session});

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  /// خريطة: studentId -> الحالة
  final Map<int, String> _attendanceStatus = {};

  /// خريطة: studentId -> المتبقي (للحصص الإضافية)
  final Map<int, double> _extraFeeRemaining = {};

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;
  bool _isLoadingExisting = true;

  /// ✅ هل الحصة إضافية؟
  bool get _isExtraSession =>
      widget.session.type == 'extra' &&
      widget.session.price != null &&
      widget.session.price! > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // جلب الحضور الموجود مسبقاً
      context.read<AttendanceBloc>().add(
        FetchAttendanceBySession(widget.session.id!),
      );
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<HomeworkBloc>().add(FetchAllHomeworks());

      // ✅ إذا كانت حصة إضافية، جلب حالة الدفع
      if (_isExtraSession) {
        context.read<FinanceBloc>().add(FetchPayments());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ تحميل الحضور الموجود مسبقاً
  void _loadExistingAttendance(List<AttendanceEntity> existing) {
    for (final att in existing) {
      _attendanceStatus[att.studentId] = att.status;
    }
    _isLoadingExisting = false;
  }

  List<int> _getGroupStudentIds() {
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    return enrollments
        .where(
          (e) => e.groupId == widget.session.groupId && e.status == 'active',
        )
        .map((e) => e.studentId)
        .toList();
  }

  /// ✅ حفظ الحضور
  void _save() {
    if (_attendanceStatus.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الحضور أولاً')));
      return;
    }

    setState(() => _isSaving = true);

    final attendanceList = _attendanceStatus.entries.map((entry) {
      return AttendanceEntity(
        sessionId: widget.session.id!,
        studentId: entry.key,
        status: entry.value,
        checkInTime: DateTime.now(),
      );
    }).toList();

    context.read<AttendanceBloc>().add(
      SaveAttendanceEvent(
        sessionId: widget.session.id!,
        attendanceList: attendanceList,
      ),
    );

    // تحديث حالة الحصة إلى "مكتملة"
    final updatedSession = widget.session.copyWith(status: 'completed');
    context.read<AttendanceBloc>().add(UpdateSessionEvent(updatedSession));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الحضور (${_attendanceStatus.length} طالب)'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  /// ✅ تعيين حالة للجميع
  void _setAllStatus(String status) {
    final studentIds = _getGroupStudentIds();
    setState(() {
      for (final id in studentIds) {
        _attendanceStatus[id] = status;
      }
    });
  }

  Future<void> _confirmUnexemption(int studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الإعفاء'),
        content: Text(
          'هل تريد إلغاء إعفاء "$studentName"؟\n\n'
          'سيصبح المبلغ مستحقاً مرة أخرى.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء الأمر'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AttendanceBloc>().add(
        UnexemptStudentFromExtraFee(
          sessionId: widget.session.id!,
          studentId: studentId,
        ),
      );

      // ✅ إعادة جلب الدفعات
      context.read<FinanceBloc>().add(FetchPayments());

      setState(() {
        _extraFeeRemaining[studentId] = widget.session.price ?? 0;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إلغاء إعفاء $studentName')));
    }
  }

  /// ✅ إعفاء طالب من الحصة الإضافية
  Future<void> _confirmExemption(int studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإعفاء'),
        content: Text(
          'هل تريد إعفاء "$studentName" من دفع الحصة الإضافية؟\n\n'
          'المبلغ المتبقي: ${_extraFeeRemaining[studentId]?.toStringAsFixed(0) ?? 0} دج',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: const Text('إعفاء'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AttendanceBloc>().add(
        ExemptStudentFromExtraFee(
          sessionId: widget.session.id!,
          studentId: studentId,
        ),
      );

      // ✅ إعادة جلب الدفعات لتحديث الواجهة فوراً
      context.read<FinanceBloc>().add(FetchPayments());

      setState(() {
        _extraFeeRemaining[studentId] = 0;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إعفاء $studentName')));
    }
  }

  /// ✅ عرض نافذة إضافة واجب
  Future<void> _showAddHomeworkDialog(BuildContext context) async {
    final homeworkBloc = context.read<HomeworkBloc>();

    await showDialog(
      context: context,
      builder: (_) => AddHomeworkDialog(
        session: widget.session,
        homeworkBloc: homeworkBloc,
      ),
    );
  }

  /// ✅ عرض نافذة تسليمات الواجب
  Future<void> _showHomeworkDetails(
    BuildContext context,
    HomeworkEntity homework,
  ) async {
    final homeworkBloc = context.read<HomeworkBloc>();
    homeworkBloc.add(FetchSubmissions(homework.id!));

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => HomeworkSubmissionsDialog(
        homework: homework,
        session: widget.session,
        homeworkBloc: homeworkBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final group = context
        .read<GroupsBloc>()
        .state
        .groupsState
        .data
        ?.where((g) => g.id == widget.session.groupId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? 'تسجيل الحضور'),
        actions: [
          // ✅ زر مسح QR
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'مسح QR',
            onPressed: () => _openQrScanner(context),
          ),
          // زر إضافة واجب
          IconButton(
            icon: const Icon(Icons.assignment_add),
            tooltip: 'إضافة واجب',
            onPressed: () => _showAddHomeworkDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _setAllStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'present',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('تعيين الجميع حاضر'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'absent',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('تعيين الجميع غائب'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'late',
                child: Row(
                  children: [
                    Icon(Icons.timelapse, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('تعيين الجميع متأخر'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          // ✅ عند جلب الحضور الموجود، نحمّله
          if (_isLoadingExisting && state.attendanceState is Success) {
            _loadExistingAttendance(state.attendanceState.data!);
            setState(() {});
          }
        },
        child: BlocListener<FinanceBloc, FinanceState>(
          listener: (context, state) {
            if (_isExtraSession) {
              setState(() {});
            }
            // ✅ عند جلب العمليات المالية، نحسب المتبقي لكل طالب
            if (_isExtraSession && state.paymentsState is Success) {
              final payments = state.paymentsState.data!;
              final sessionPayments = payments.where(
                (p) => p.sessionId == widget.session.id && p.type == 'extra',
              );
              setState(() {
                for (final p in sessionPayments) {
                  _extraFeeRemaining[p.studentId] = p.remainingAmount;
                }
              });
            }
          },
          child: Column(
            children: [
              // ====== بطاقة معلومات الحصة ======
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.sp,
                          color: colors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          DateFormat(
                            'yyyy/MM/dd',
                          ).format(widget.session.sessionDate),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.schedule,
                          size: 16.sp,
                          color: colors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${DateFormat('HH:mm').format(widget.session.startTime)} - ${DateFormat('HH:mm').format(widget.session.endTime)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_isExtraSession) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 16.sp,
                              color: colors.onTertiaryContainer,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'حصة إضافية مدفوعة',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: colors.onTertiaryContainer,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.session.price!.toStringAsFixed(0)} دج',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: colors.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    _AttendanceSummary(attendanceStatus: _attendanceStatus),
                  ],
                ),
              ),

              // ✅ عرض واجبات الحصة السابقة
              BlocBuilder<HomeworkBloc, HomeworkState>(
                builder: (context, state) {
                  if (state.homeworksState is! Success)
                    return const SizedBox.shrink();
                  final allHomeworks = state.homeworksState.data ?? [];

                  // ✅ البحث: targetSessionId == session.id
                  final homeworks = allHomeworks
                      .where((h) => h.targetSessionId == widget.session.id)
                      .toList();

                  if (homeworks.isEmpty) return const SizedBox.shrink();

                  /* 
                  // الواجبات المرتبطة بهذه الحصة (targetSessionId == session.id)
                  final homeworks = allHomeworks
                      .where((h) => h.targetSessionId == widget.session.id)
                      .toList();
 */

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(_kRadius),
                      border: Border.all(
                        color: colors.tertiary.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              size: 18.sp,
                              color: colors.tertiary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'واجبات مستحقة التسليم',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: colors.tertiary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ...homeworks.map(
                          (hw) => Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6.sp,
                                  color: colors.tertiary,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hw.title,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      _showHomeworkDetails(context, hw),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    minimumSize: Size(0, 28.h),
                                  ),
                                  child: const Text(
                                    'التسليم',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 8.h),

              // ====== حقل البحث ======
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طالب...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // ====== قائمة الطلاب ======
              // ====== قائمة الطلاب ======
              Expanded(
                child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
                  builder: (context, enrollmentState) {
                    return BlocBuilder<StudentsBloc, StudentsState>(
                      builder: (context, studentsState) {
                        // ✅ استخدم BlocBuilder للـ FinanceBloc
                        return BlocBuilder<FinanceBloc, FinanceState>(
                          builder: (context, financeState) {
                            final enrollments =
                                enrollmentState.enrollmentsState.data ?? [];
                            final students =
                                studentsState.studentsState.data ?? [];
                            final payments =
                                financeState.paymentsState.data ?? [];

                            final groupStudentIds = enrollments
                                .where(
                                  (e) =>
                                      e.groupId == widget.session.groupId &&
                                      e.status == 'active',
                                )
                                .map((e) => e.studentId)
                                .toSet();

                            var groupStudents = students
                                .where((s) => groupStudentIds.contains(s.id))
                                .toList();

                            if (_searchQuery.isNotEmpty) {
                              groupStudents = groupStudents
                                  .where(
                                    (s) =>
                                        s.fullName.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                        s.studentCode.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ),
                                  )
                                  .toList();
                            }

                            if (groupStudents.isEmpty) {
                              return Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'لا يوجد طلاب مسجلون في هذا الفوج'
                                      : 'لا توجد نتائج للبحث',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              itemCount: groupStudents.length,
                              itemBuilder: (context, index) {
                                final student = groupStudents[index];
                                final status = _attendanceStatus[student.id];

                                // ✅ ابحث عن العملية المالية لهذا الطالب في هذه الحصة
                                final payment = payments
                                    .where(
                                      (p) =>
                                          p.studentId == student.id &&
                                          p.sessionId == widget.session.id &&
                                          p.type == 'extra',
                                    )
                                    .firstOrNull;

                                final remaining =
                                    payment?.remainingAmount ??
                                    widget.session.price;

                                return _StudentAttendanceCard(
                                  studentName: student.fullName,
                                  studentCode: student.studentCode,
                                  currentStatus: status,
                                  onStatusChanged: (newStatus) {
                                    setState(
                                      () => _attendanceStatus[student.id!] =
                                          newStatus,
                                    );
                                  },
                                  isExtraSession: _isExtraSession,
                                  price: widget.session.price,
                                  remainingAmount: remaining,
                                  onExempt: (remaining != null && remaining > 0)
                                      ? () => _confirmExemption(
                                          student.id!,
                                          student.fullName,
                                        )
                                      : null,
                                  onUnexempt:
                                      (remaining != null &&
                                          remaining == 0 &&
                                          payment != null)
                                      ? () => _confirmUnexemption(
                                          student.id!,
                                          student.fullName,
                                        )
                                      : null,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('حفظ الحضور'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ فتح صفحة المسح المتسلسل
  Future<void> _openQrScanner(BuildContext context) async {
    // ✅ جلب طلاب الفوج
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];

    final groupStudentIds = enrollments
        .where(
          (e) => e.groupId == widget.session.groupId && e.status == 'active',
        )
        .map((e) => e.studentId)
        .toSet();

    final groupStudents = students
        .where((s) => groupStudentIds.contains(s.id))
        .toList();

    if (groupStudents.isEmpty) {
      _showSnack('لا يوجد طلاب في هذا الفوج');
      return;
    }

    // ✅ فتح صفحة المسح
    final result = await Navigator.of(context).push<QrScanResult>(
      MaterialPageRoute(
        builder: (_) => QrScannerPage(
          groupStudents: groupStudents,
          initialAttendance: Map.from(_attendanceStatus),
        ),
      ),
    );

    if (result == null || !mounted) return;

    // ✅ تحديث الحضور
    if (result.saved) {
      setState(() {
        _attendanceStatus.clear();
        _attendanceStatus.addAll(result.attendanceMap);
      });

      _showSnack(
        'تم مسح ${result.attendanceMap.values.where((s) => s == 'present').length} طالب',
      );
    }
  }

  /// ✅ عرض تأكيد المسح
  void _showQrSuccess(String studentName) {
    final colors = Theme.of(context).colorScheme;

    // صوت/اهتزاز (اختياري)
    // SystemSound.play(SystemSoundType.click);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // إغلاق تلقائي بعد 1.5 ثانية
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64.sp, color: Colors.white),
                SizedBox(height: 12.h),
                Text(
                  studentName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'تم تسجيل الحضور ✓',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ عرض SnackBar
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 📊 ملخص الحضور
class _AttendanceSummary extends StatelessWidget {
  final Map<int, String> attendanceStatus;
  const _AttendanceSummary({required this.attendanceStatus});

  @override
  Widget build(BuildContext context) {
    final present = attendanceStatus.values.where((s) => s == 'present').length;
    final absent = attendanceStatus.values.where((s) => s == 'absent').length;
    final late = attendanceStatus.values.where((s) => s == 'late').length;
    final total = attendanceStatus.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SummaryItem(
          label: 'الكل',
          value: '$total',
          color: Theme.of(context).colorScheme.onSurface,
        ),
        _SummaryItem(label: 'حاضر', value: '$present', color: Colors.green),
        _SummaryItem(label: 'غائب', value: '$absent', color: Colors.red),
        _SummaryItem(label: 'متأخر', value: '$late', color: Colors.orange),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontSize: 10.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 📁 بطاقة طالب لتسجيل الحضور
class _StudentAttendanceCard extends StatelessWidget {
  final String studentName;
  final String studentCode;
  final String? currentStatus;
  final ValueChanged<String> onStatusChanged;

  // ✅ جديد: للحصص الإضافية
  final bool isExtraSession;
  final double? price;
  final double? remainingAmount;
  final VoidCallback? onExempt;
  final VoidCallback? onUnexempt;

  const _StudentAttendanceCard({
    required this.studentName,
    required this.studentCode,
    required this.currentStatus,
    required this.onStatusChanged,
    this.isExtraSession = false,
    this.price,
    this.remainingAmount,
    this.onExempt,
    this.onUnexempt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final statusColor = switch (currentStatus) {
      'present' => Colors.green,
      'absent' => Colors.red,
      'late' => Colors.orange,
      _ => colors.onSurfaceVariant,
    };

    final isExempted = remainingAmount != null && remainingAmount == 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 6.h),
      color: currentStatus != null
          ? statusColor.withOpacity(0.05)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: currentStatus != null
              ? statusColor.withOpacity(0.3)
              : colors.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    studentName.isNotEmpty ? studentName.substring(0, 1) : '؟',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'الرقم: $studentCode',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ✅ شريط الحصة الإضافية (فقط للحصص الإضافية)
            if (isExtraSession && price != null && price! > 0) ...[
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isExempted
                      ? colors.tertiaryContainer.withOpacity(0.3)
                      : colors.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isExempted
                        ? colors.tertiary.withOpacity(0.3)
                        : colors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExempted
                          ? Icons.card_giftcard
                          : Icons.payments_outlined,
                      size: 14.sp,
                      color: isExempted ? colors.tertiary : colors.error,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${price!.toStringAsFixed(0)} دج',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isExempted ? colors.tertiary : colors.error,
                      ),
                    ),
                    if (remainingAmount != null && remainingAmount! > 0) ...[
                      const Spacer(),
                      Text(
                        'متبقي: ${remainingAmount!.toStringAsFixed(0)} دج',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.error,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // ✅ زر الإعفاء
                      if (onExempt != null)
                        InkWell(
                          onTap: onExempt,
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: colors.tertiary,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 12.sp,
                                  color: colors.onTertiary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'إعفاء',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else if (isExempted) ...[
                      const Spacer(),
                      Text(
                        'معفى ✓',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.tertiary,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // ✅ زر إلغاء الإعفاء
                      if (onUnexempt != null)
                        InkWell(
                          onTap: onUnexempt,
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: colors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.undo,
                                  size: 12.sp,
                                  color: colors.error,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      const Spacer(),
                      Text(
                        'مدفوع ✓',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 8.h),

            // ✅ أزرار الحالات (3 حالات)
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'حاضر',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    isSelected: currentStatus == 'present',
                    onTap: () => onStatusChanged('present'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _StatusButton(
                    label: 'غائب',
                    icon: Icons.cancel,
                    color: Colors.red,
                    isSelected: currentStatus == 'absent',
                    onTap: () => onStatusChanged('absent'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _StatusButton(
                    label: 'متأخر',
                    icon: Icons.timelapse,
                    color: Colors.orange,
                    isSelected: currentStatus == 'late',
                    onTap: () => onStatusChanged('late'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 زر حالة
class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: isSelected ? Colors.white : color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

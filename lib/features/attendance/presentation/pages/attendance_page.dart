import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/attendance/presentation/pages/take_attendance_page.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';

import '../../../../injection_container.dart';
import '../../../notifications/presentation/widgets/sms_dialog.dart';
import '../../../notifications/services/sms_service.dart';
import '../../../notifications/services/template_service.dart';

// ثوابت التصميم
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/* /// 📁 صفحة الحضور والغياب الرئيسية
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(FetchTodaySessions());
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحضور والغياب'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () {
                context.read<AttendanceBloc>().add(FetchTodaySessions());
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'حصص اليوم', icon: Icon(Icons.today, size: 18)),
              Tab(text: 'كل الحصص', icon: Icon(Icons.history, size: 18)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TodaySessionsTab(), _AllSessionsTab()],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_session_fab',
          onPressed: () => _showCreateSessionDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    final attendanceBloc = context.read<AttendanceBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<GroupsBloc, GroupsState>(
          builder: (dialogContext, groupsState) {
            final groups = groupsState.groupsState.data ?? [];

            if (groups.isEmpty) {
              return AlertDialog(
                title: const Text('تنبيه'),
                content: const Text('لا توجد أفواج. يرجى إضافة الأفواج أولاً.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              );
            }

            return _CreateSessionDialog(
              groups: groups,
              attendanceBloc: attendanceBloc,
            );
          },
        );
      },
    );
  }
}
 */
/// 📁 صفحة الحضور والغياب الرئيسية
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(FetchTodaySessions());
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحضور والغياب'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () {
                context.read<AttendanceBloc>().add(FetchTodaySessions());
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'حصص اليوم', icon: Icon(Icons.today, size: 18)),
              Tab(text: 'كل الحصص', icon: Icon(Icons.history, size: 18)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TodaySessionsTab(), _AllSessionsTab()],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_session_fab',
          onPressed: () => _showCreateSessionDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    final attendanceBloc = context.read<AttendanceBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<GroupsBloc, GroupsState>(
          builder: (dialogContext, groupsState) {
            final groups = groupsState.groupsState.data ?? [];

            if (groups.isEmpty) {
              return AlertDialog(
                title: const Text('تنبيه'),
                content: const Text('لا توجد أفواج. يرجى إضافة الأفواج أولاً.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              );
            }

            return _CreateSessionDialog(
              groups: groups,
              attendanceBloc: attendanceBloc,
            );
          },
        );
      },
    );
  }
}

/// 📁 تبويب "كل الحصص" - احترافي مع تصفية حسب التاريخ
class _AllSessionsTab extends StatefulWidget {
  const _AllSessionsTab();

  @override
  State<_AllSessionsTab> createState() => _AllSessionsTabState();
}

/// 📁 تبويب حصص اليوم
class _TodaySessionsTab extends StatelessWidget {
  const _TodaySessionsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        return switch (state.sessionsState) {
          Initial() => const SizedBox.shrink(),
          Loading() => const Center(child: CircularProgressIndicator()),
          Empty() => const _EmptyState(
            icon: Icons.event_busy,
            message: 'لا توجد حصص اليوم',
          ),
          Error(message: final msg) => Center(child: Text(msg)),
          Success(data: final sessions) =>
            // ✅ الحل: BlocBuilder للأفواج
            BlocBuilder<GroupsBloc, GroupsState>(
              builder: (context, groupsState) {
                return ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return _SessionCard(session: sessions[index]);
                  },
                );
              },
            ),
        };
      },
    );
  }
}

class _AllSessionsTabState extends State<_AllSessionsTab> {
  // ✅ التاريخ الحالي افتراضياً
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ✅ جلب الحصص للتاريخ الحالي عند فتح التبويب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionsForDate(_selectedDate);
    });
  }

  /// ✅ جلب الحصص لتاريخ معين (مع توليد الحصص العادية تلقائياً إذا لم تكن موجودة)
  void _loadSessionsForDate(DateTime date) {
    // 1. توليد الحصص العادية تلقائياً لهذا التاريخ
    context.read<AttendanceBloc>().add(GenerateSessionsForDate(date));
    // 2. جلب كل الحصص في ذلك اليوم
    context.read<AttendanceBloc>().add(FetchSessionsByDate(date));
  }

  /// ✅ اختيار تاريخ جديد
  Future<void> _pickDate() async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: _selectedDate,
      minDate: DateTime.now().subtract(const Duration(days: 730)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadSessionsForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ====== شريط التاريخ ======
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18.sp, color: colors.primary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التاريخ المحدد',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE، d MMMM yyyy',
                          'ar',
                        ).format(_selectedDate),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // أزرار التنقل السريع
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colors.primary),
                  tooltip: 'اليوم السابق',
                  onPressed: () {
                    final newDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                    setState(() => _selectedDate = newDate);
                    _loadSessionsForDate(newDate);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: colors.primary),
                  tooltip: 'اختيار تاريخ',
                  onPressed: _pickDate,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colors.primary),
                  tooltip: 'اليوم التالي',
                  onPressed: () {
                    final newDate = _selectedDate.add(const Duration(days: 1));
                    setState(() => _selectedDate = newDate);
                    _loadSessionsForDate(newDate);
                  },
                ),
              ],
            ),
          ),
        ),

        // ====== قائمة الحصص ======
        Expanded(
          child: BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, state) {
              return switch (state.sessionsState) {
                Initial() => const SizedBox.shrink(),
                Loading() => const Center(child: CircularProgressIndicator()),
                Empty() => const _EmptyState(
                  icon: Icons.event_busy,
                  message: 'لا توجد حصص في هذا التاريخ',
                ),
                Error(message: final msg) => Center(child: Text(msg)),
                Success(data: final sessions) => (() {
                  // ✅ تصفية الحصص حسب التاريخ المحدد
                  final filtered = sessions.where((s) {
                    return s.sessionDate.year == _selectedDate.year &&
                        s.sessionDate.month == _selectedDate.month &&
                        s.sessionDate.day == _selectedDate.day;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.event_busy,
                      message: 'لا توجد حصص في هذا التاريخ',
                    );
                  }

                  // ✅ ترتيب حسب وقت البداية
                  filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

                  // ✅ الحل: BlocBuilder للأفواج حول ListView
                  return BlocBuilder<GroupsBloc, GroupsState>(
                    builder: (context, groupsState) {
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _SessionCard(session: filtered[index]);
                        },
                      );
                    },
                  );
                })(),
              };
            },
          ),
        ),
      ],
    );
  }
}

/// 📁 بطاقة الحصة
class _SessionCard extends StatelessWidget {
  final SessionEntity session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // ✅ استخدام BlocBuilder للأفواج لإعادة البناء عند تحميلها
    return BlocBuilder<GroupsBloc, GroupsState>(
      builder: (context, groupsState) {
        final groups = groupsState.groupsState.data ?? [];
        final group = groups.where((g) => g.id == session.groupId).firstOrNull;

        final (statusColor, statusLabel) = switch (session.status) {
          'completed' => (colors.secondary, 'مكتملة'),
          'cancelled' => (colors.error, 'ملغاة'),
          'postponed' => (colors.primary, 'مؤجلة'),
          'in_progress' => (colors.primary, 'قيد التنفيذ'),
          _ => (Colors.blue, 'مجدولة'),
        };

        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(_kRadius),
            onTap: () {
              if (session.status == 'cancelled') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا يمكن تسجيل الحضور في حصة ملغاة'),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TakeAttendancePage(session: session),
                ),
              );
            },
            onLongPress: () => _showSessionMenu(context),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: colors.secondaryContainer,
                        child: Icon(
                          Icons.groups,
                          size: 20.sp,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // ✅ عرض اسم الفوج
                              group?.name ?? 'جاري التحميل...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'yyyy/MM/dd',
                              ).format(session.sessionDate),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14.sp,
                        color: colors.onSurfaceVariant,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.label_outline,
                        size: 14.sp,
                        color: colors.onSurfaceVariant,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        session.typeLabel,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (session.type == 'extra' && session.price != null) ...[
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.payments_outlined,
                          size: 14.sp,
                          color: colors.tertiary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${session.price!.toStringAsFixed(0)} دج',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: colors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (session.cancelReason != null &&
                      session.cancelReason!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12.sp,
                            color: colors.error,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'السبب: ${session.cancelReason}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ✅ قائمة السياق
  void _showSessionMenu(BuildContext context) {
    final attendanceBloc = context.read<AttendanceBloc>();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ للحصص الاستثنائية (تعويضية/إضافية): تعديل وحذف
            if (session.type == 'makeup' || session.type == 'extra') ...[
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('تعديل الحصة'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showEditSessionDialog(context, attendanceBloc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'حذف الحصة',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, attendanceBloc);
                },
              ),
            ],
            // ✅ للحصص العادية: إلغاء/تأجيل
            if (session.type == 'regular') ...[
              if (session.status != 'cancelled')
                ListTile(
                  leading: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'إلغاء الحصة',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmCancel(context, attendanceBloc);
                  },
                ),
              if (session.status == 'cancelled')
                ListTile(
                  leading: Icon(
                    Icons.restore,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'إعادة إلى "عادية"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _restoreSession(context, attendanceBloc);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.post_add, color: Colors.blue),
                title: const Text(
                  'تأجيل الحصة',
                  style: TextStyle(color: Colors.blue),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmPostpone(context, attendanceBloc);
                },
              ),
            ],

            // ✅ للحصص التعويضية: إرسال SMS
            if (session.type == 'makeup')
              ListTile(
                leading: Icon(
                  Icons.sms,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('إرسال SMS للأولياء'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showSmsDialogForMakeup(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSmsDialogForMakeup(BuildContext context) async {
    final templateService = getIt<TemplateService>();
    final smsService = getIt<SmsService>();

    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final group = groups.where((g) => g.id == session.groupId).firstOrNull;
    if (group == null) return;

    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];

    final studentIds = enrollments
        .where((e) => e.groupId == session.groupId && e.status == 'active')
        .map((e) => e.studentId)
        .toSet();

    final groupStudents = students
        .where((s) => studentIds.contains(s.id))
        .toList();

    final recipients = <SmsRecipient>[];
    for (final student in groupStudents) {
      if (student.phone != null && student.phone!.isNotEmpty) {
        recipients.add(
          SmsRecipient(
            id: student.id,
            name: 'ولي أمر ${student.fullName}',
            phone: student.phone!,
          ),
        );
      }
    }

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد أرقام هواتف')));
      return;
    }

    final message = templateService.renderMakeupSession(
      groupName: group.name,
      date: DateFormat('yyyy/MM/dd').format(session.sessionDate),
      startTime: DateFormat('HH:mm').format(session.startTime),
      endTime: DateFormat('HH:mm').format(session.endTime),
    );

    await showDialog(
      context: context,
      builder: (_) => SmsDialog(
        recipients: recipients,
        initialMessage: message,
        smsService: smsService,
      ),
    );
  }

  /// ✅ تعديل الحصة
  void _showEditSessionDialog(
    BuildContext context,
    AttendanceBloc attendanceBloc,
  ) {
    final groupsState = context.read<GroupsBloc>().state;
    final groups = groupsState.groupsState.data ?? [];

    showDialog(
      context: context,
      builder: (_) => _EditSessionDialog(
        session: session,
        groups: groups,
        attendanceBloc: attendanceBloc,
      ),
    );
  }

  /// ✅ حذف الحصة
  Future<void> _confirmDelete(
    BuildContext context,
    AttendanceBloc attendanceBloc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الحصة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      attendanceBloc.add(DeleteSessionEvent(session.id!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الحصة')));
    }
  }

  /// ✅ إلغاء الحصة (مع سبب)
  Future<void> _confirmCancel(
    BuildContext context,
    AttendanceBloc attendanceBloc,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الحصة'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'سبب الإلغاء (اختياري)',
            hintText: 'مثال: عطلة رسمية',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      final updated = session.copyWith(
        status: 'cancelled',
        cancelReason: reason.isEmpty ? null : reason,
      );
      attendanceBloc.add(UpdateSessionEvent(updated));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الحصة')));

      // ✅ عرض حوار إرسال SMS
      await _showSmsDialogForGroup(context, reason);
    }
  }

  /// ✅ عرض حوار إرسال SMS لأولياء أمور الفوج
  Future<void> _showSmsDialogForGroup(
    BuildContext context,
    String reason,
  ) async {
    final templateService = getIt<TemplateService>();
    final smsService = getIt<SmsService>();

    // جلب اسم الفوج
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final group = groups.where((g) => g.id == session.groupId).firstOrNull;
    if (group == null) return;

    // جلب طلاب الفوج
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final students =
        context.read<StudentsBloc>().state.studentsState.data ?? [];

    final studentIds = enrollments
        .where((e) => e.groupId == session.groupId && e.status == 'active')
        .map((e) => e.studentId)
        .toSet();

    final groupStudents = students
        .where((s) => studentIds.contains(s.id))
        .toList();

    // جلب أولياء الأمور (لاحقاً: من Guardian)
    // حالياً: نستخدم رقم الطالب أو نطلب إضافته
    final recipients = <SmsRecipient>[];
    for (final student in groupStudents) {
      if (student.phone != null && student.phone!.isNotEmpty) {
        recipients.add(
          SmsRecipient(
            id: student.id,
            name: 'ولي أمر ${student.fullName}',
            phone: student.phone!,
          ),
        );
      }
    }

    if (recipients.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد أرقام هواتف للأولياء')),
        );
      }
      return;
    }

    // توليد الرسالة
    final message = templateService.renderSessionCancelled(
      groupName: group.name,
      date: DateFormat('yyyy/MM/dd').format(session.sessionDate),
      startTime: DateFormat('HH:mm').format(session.startTime),
      endTime: DateFormat('HH:mm').format(session.endTime),
      reason: reason.isEmpty ? 'غير محدد' : reason,
    );

    // عرض حوار SMS
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => SmsDialog(
          recipients: recipients,
          initialMessage: message,
          smsService: smsService,
        ),
      );
    }
  }

  /// ✅ إعادة الحصة إلى "عادية"
  void _restoreSession(BuildContext context, AttendanceBloc attendanceBloc) {
    final updated = session.copyWith(status: 'scheduled', cancelReason: null);
    attendanceBloc.add(UpdateSessionEvent(updated));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إعادة الحصة')));
  }

  /// ✅ تأجيل الحصة
  Future<void> _confirmPostpone(
    BuildContext context,
    AttendanceBloc attendanceBloc,
  ) async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: session.sessionDate.add(const Duration(days: 7)),
      minDate: DateTime.now(),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && context.mounted) {
      // نغير التاريخ والوقت معاً
      final newStart = DateTime(
        picked.year,
        picked.month,
        picked.day,
        session.startTime.hour,
        session.startTime.minute,
      );
      final newEnd = DateTime(
        picked.year,
        picked.month,
        picked.day,
        session.endTime.hour,
        session.endTime.minute,
      );

      final updated = session.copyWith(
        sessionDate: DateTime(picked.year, picked.month, picked.day),
        startTime: newStart,
        endTime: newEnd,
        status: 'postponed',
      );

      attendanceBloc.add(UpdateSessionEvent(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تأجيل الحصة إلى ${DateFormat('yyyy/MM/dd').format(picked)}',
          ),
        ),
      );
    }
  }
}

/// 📁 حالة فارغة
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: colors.onSurfaceVariant),
          SizedBox(height: 12.h),
          Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ============================================================
// 📁 حوار إنشاء حصة
// ============================================================
class _CreateSessionDialog extends StatefulWidget {
  final List<GroupEntity> groups;
  final AttendanceBloc attendanceBloc;

  const _CreateSessionDialog({
    required this.groups,
    required this.attendanceBloc,
  });

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  int? _selectedGroupId;
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _sessionType = 'makeup';
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.groups.isNotEmpty) {
      _selectedGroupId = widget.groups.first.id;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: _sessionDate,
      minDate: DateTime.now().subtract(const Duration(days: 30)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الفوج')));
      return;
    }

    if (_sessionType == 'extra') {
      final price = double.tryParse(_priceController.text) ?? 0;
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال سعر الحصة الإضافية')),
        );
        return;
      }
    }

    final sessionDate = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
    );
    final startTime = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وقت النهاية يجب أن يكون بعد وقت البداية'),
        ),
      );
      return;
    }

    final price = _sessionType == 'extra'
        ? double.tryParse(_priceController.text) ?? 0
        : null;

    final session = SessionEntity(
      groupId: _selectedGroupId!,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: endTime,
      type: _sessionType,
      status: 'scheduled',
      lessonTopic: _topicController.text.isEmpty ? null : _topicController.text,
      teacherNotes: _notesController.text.isEmpty
          ? null
          : _notesController.text,
      isPaid: _sessionType == 'extra',
      price: price,
    );

    widget.attendanceBloc.add(CreateSessionEvent(session));

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إنشاء الحصة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.event,
                      size: 20.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'إنشاء حصة استثنائية',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Gap.lg),

              // الفوج
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'الفوج *',
                  prefixIcon: Icon(Icons.groups_outlined, size: 18),
                  isDense: true,
                ),
                items: widget.groups.map((group) {
                  return DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedGroupId = value),
              ),
              SizedBox(height: _Gap.md),

              // نوع الحصة
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _sessionType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحصة *',
                  prefixIcon: Icon(Icons.label_outline, size: 18),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'makeup', child: Text('تعويضية')),
                  DropdownMenuItem(value: 'extra', child: Text('إضافية')),
                ],
                onChanged: (value) =>
                    setState(() => _sessionType = value ?? 'makeup'),
              ),
              SizedBox(height: _Gap.md),

              // التاريخ
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10.r),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ *',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                    isDense: true,
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd').format(_sessionDate),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              SizedBox(height: _Gap.md),

              // الأوقات
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'من',
                          prefixIcon: Icon(Icons.schedule, size: 18),
                          isDense: true,
                        ),
                        child: Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'إلى',
                          prefixIcon: Icon(Icons.schedule, size: 18),
                          isDense: true,
                        ),
                        child: Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Gap.md),

              // ✅ حقل السعر (للحصص الإضافية فقط)
              if (_sessionType == 'extra') ...[
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر الحصة (دج) *',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                    isDense: true,
                  ),
                ),
                SizedBox(height: _Gap.md),
              ],

              // موضوع الدرس
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'موضوع الدرس (اختياري)',
                  prefixIcon: Icon(Icons.book_outlined, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.md),

              // ملاحظات
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('إنشاء'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 📁 حوار تعديل حصة استثنائية
// ============================================================
class _EditSessionDialog extends StatefulWidget {
  final SessionEntity session;
  final List<GroupEntity> groups;
  final AttendanceBloc attendanceBloc;

  const _EditSessionDialog({
    required this.session,
    required this.groups,
    required this.attendanceBloc,
  });

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late int? _selectedGroupId;
  late DateTime _sessionDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _sessionType;
  late final TextEditingController _topicController;
  late final TextEditingController _notesController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.session.groupId;
    _sessionDate = widget.session.sessionDate;
    _startTime = TimeOfDay(
      hour: widget.session.startTime.hour,
      minute: widget.session.startTime.minute,
    );
    _endTime = TimeOfDay(
      hour: widget.session.endTime.hour,
      minute: widget.session.endTime.minute,
    );
    _sessionType = widget.session.type;
    _topicController = TextEditingController(
      text: widget.session.lessonTopic ?? '',
    );
    _notesController = TextEditingController(
      text: widget.session.teacherNotes ?? '',
    );
    _priceController = TextEditingController(
      text: widget.session.price != null
          ? widget.session.price!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: _sessionDate,
      minDate: DateTime.now().subtract(const Duration(days: 30)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_selectedGroupId == null) return;

    if (_sessionType == 'extra') {
      final price = double.tryParse(_priceController.text) ?? 0;
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال سعر الحصة الإضافية')),
        );
        return;
      }
    }

    final sessionDate = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
    );
    final startTime = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وقت النهاية يجب أن يكون بعد وقت البداية'),
        ),
      );
      return;
    }

    final price = _sessionType == 'extra'
        ? double.tryParse(_priceController.text) ?? 0
        : null;

    final updated = widget.session.copyWith(
      groupId: _selectedGroupId!,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: endTime,
      type: _sessionType,
      lessonTopic: _topicController.text.isEmpty ? null : _topicController.text,
      teacherNotes: _notesController.text.isEmpty
          ? null
          : _notesController.text,
      isPaid: _sessionType == 'extra',
      price: price,
    );

    widget.attendanceBloc.add(UpdateSessionEvent(updated));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث الحصة')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.edit,
                      size: 20.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'تعديل الحصة',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Gap.lg),

              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'الفوج *',
                  prefixIcon: Icon(Icons.groups_outlined, size: 18),
                  isDense: true,
                ),
                items: widget.groups.map((group) {
                  return DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedGroupId = value),
              ),
              SizedBox(height: _Gap.md),

              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _sessionType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحصة *',
                  prefixIcon: Icon(Icons.label_outline, size: 18),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'makeup', child: Text('تعويضية')),
                  DropdownMenuItem(value: 'extra', child: Text('إضافية')),
                ],
                onChanged: (value) =>
                    setState(() => _sessionType = value ?? 'makeup'),
              ),
              SizedBox(height: _Gap.md),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10.r),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ *',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                    isDense: true,
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd').format(_sessionDate),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              SizedBox(height: _Gap.md),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'من',
                          prefixIcon: Icon(Icons.schedule, size: 18),
                          isDense: true,
                        ),
                        child: Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'إلى',
                          prefixIcon: Icon(Icons.schedule, size: 18),
                          isDense: true,
                        ),
                        child: Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Gap.md),

              if (_sessionType == 'extra') ...[
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر الحصة (دج) *',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                    isDense: true,
                  ),
                ),
                SizedBox(height: _Gap.md),
              ],

              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'موضوع الدرس (اختياري)',
                  prefixIcon: Icon(Icons.book_outlined, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.md),

              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

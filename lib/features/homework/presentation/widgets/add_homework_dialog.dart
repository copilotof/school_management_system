import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:school_management_system/injection_container.dart';

import '../../../attendance/data/models/attendance_mapper.dart';

class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 نافذة إضافة/تعديل واجب - مبسطة
class AddHomeworkDialog extends StatefulWidget {
  final SessionEntity session;
  final HomeworkEntity? homework;
  final HomeworkBloc homeworkBloc;

  const AddHomeworkDialog({
    super.key,
    required this.session,
    this.homework,
    required this.homeworkBloc,
  });

  @override
  State<AddHomeworkDialog> createState() => _AddHomeworkDialogState();
}

class _AddHomeworkDialogState extends State<AddHomeworkDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  late DateTime _dueDate;
  SessionEntity? _targetSession; // الحصة التي تُسلَّم فيها
  bool _isCheckingDate = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final hw = widget.homework;
    _titleController = TextEditingController(text: hw?.title ?? '');
    _descriptionController = TextEditingController(text: hw?.description ?? '');
    _notesController = TextEditingController(text: hw?.notes ?? '');

    // ✅ تاريخ التسليم: من الواجب أو بعد 7 أيام
    _dueDate = hw?.dueDate ?? DateTime.now().add(const Duration(days: 7));

    // ✅ التحقق من تاريخ التسليم الافتراضي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDateAndLoadSession(_dueDate);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// ✅ اختيار تاريخ التسليم
  Future<void> _pickDueDate() async {
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: _dueDate,
      minDate: widget.session.sessionDate,
      maxDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      await _checkDateAndLoadSession(picked);
    }
  }

  /// ✅ التحقق من وجود حصة في التاريخ + توليد إذا لزم
  Future<void> _checkDateAndLoadSession(DateTime date) async {
    setState(() {
      _isCheckingDate = true;
      _targetSession = null;
    });

    try {
      final db = getIt<AppDatabase>();

      // 1. البحث عن حصة في ذلك اليوم
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final existing =
          await (db.select(db.sessions)..where(
                (t) =>
                    t.groupId.equals(widget.session.groupId) &
                    t.sessionDate.isBetweenValues(startOfDay, endOfDay),
              ))
              .getSingleOrNull();

      if (existing != null) {
        // ✅ وجدت حصة
        setState(() {
          _targetSession = existing.toEntity();
          _isCheckingDate = false;
        });
        return;
      }

      // 2. لم توجد حصة - حاول توليدها من الجدول الأسبوعي
      final dayOfWeek = date.weekday % 7;

      final templates =
          await (db.select(db.scheduleTemplates)..where(
                (t) =>
                    t.groupId.equals(widget.session.groupId) &
                    t.dayOfWeek.equals(dayOfWeek) &
                    t.isActive.equals(true),
              ))
              .get();

      if (templates.isEmpty) {
        // ❌ لا يوجد قالب لهذا اليوم
        if (mounted) {
          setState(() => _isCheckingDate = false);
          _showErrorDialog(
            'لا توجد حصة مجدولة في هذا التاريخ',
            'لا توجد حصة مجدولة لهذا الفوج في التاريخ المختار. يرجى اختيار تاريخ آخر.',
          );
        }
        return;
      }

      // ✅ توليد الحصة
      final template = templates.first;
      final sessionDate = DateTime(date.year, date.month, date.day);
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        template.startTime.hour,
        template.startTime.minute,
      );
      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        template.endTime.hour,
        template.endTime.minute,
      );

      final newSession = SessionsCompanion.insert(
        groupId: widget.session.groupId,
        templateId: drift.Value(template.id),
        sessionDate: sessionDate,
        startTime: startTime,
        endTime: endTime,
        type: const drift.Value('regular'),
        status: const drift.Value('scheduled'),
      );

      final newId = await db.into(db.sessions).insert(newSession);
      final inserted = await (db.select(
        db.sessions,
      )..where((t) => t.id.equals(newId))).getSingleOrNull();

      if (inserted != null && mounted) {
        setState(() {
          _targetSession = inserted.toEntity();
          _isCheckingDate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingDate = false);
        _showErrorDialog('خطأ', 'حدث خطأ أثناء البحث: $e');
      }
    }
  }

  /// ✅ نافذة تنبيه
  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال عنوان الواجب');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال محتوى الواجب');
      return;
    }

    if (_targetSession == null) {
      setState(
        () => _errorMessage = 'يرجى اختيار تاريخ تسليم صحيح (يوجد فيه حصة)',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final homework = HomeworkEntity(
      id: widget.homework?.id,
      sessionId: widget.session.id!,
      targetSessionId: _targetSession!.id,
      groupId: widget.session.groupId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.homework?.createdAt,
    );

    if (widget.homework == null) {
      widget.homeworkBloc.add(CreateHomeworkEvent(homework));
    } else {
      widget.homeworkBloc.add(UpdateHomeworkEvent(homework));
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.homework == null ? 'تم إضافة الواجب' : 'تم تحديث الواجب',
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  /// ✅ عرض تنبيه داخل النافذة
  void _showErrorInDialog(String message) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 22.sp),
            SizedBox(width: 8.w),
            const Text('تنبيه'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
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
            // ====== الرأس ======
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.assignment,
                      size: 20.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.homework == null ? 'إضافة واجب' : 'تعديل الواجب',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
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

            // ====== المحتوى ======
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ====== العنوان ======
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الواجب *',
                        prefixIcon: Icon(Icons.title, size: 18),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: _Gap.md),

                    // ====== الوصف ======
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'محتوى الواجب *',
                        hintText: 'مثال: حل التمارين 1-5 ص 42',
                        alignLabelWithHint: true,
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: _Gap.md),

                    // ====== تاريخ التسليم ======
                    InkWell(
                      onTap: _isCheckingDate ? null : _pickDueDate,
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ التسليم *',
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                          isDense: true,
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('yyyy/MM/dd').format(_dueDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            if (_isCheckingDate)
                              SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else if (_targetSession != null)
                              Icon(
                                Icons.check_circle,
                                size: 16.sp,
                                color: colors.secondary,
                              )
                            else
                              Icon(
                                Icons.error_outline,
                                size: 16.sp,
                                color: colors.error,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ====== حالة الحصة ======
                    SizedBox(height: 8.h),
                    if (_isCheckingDate)
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14.w,
                              height: 14.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'جاري التحقق من الحصة...',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_targetSession != null)
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: colors.secondary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 16.sp,
                              color: colors.secondary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'الحصة: ${DateFormat('HH:mm').format(_targetSession!.startTime)} - ${DateFormat('HH:mm').format(_targetSession!.endTime)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: colors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: colors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 16.sp,
                              color: colors.error,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'لا توجد حصة في هذا التاريخ',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: _Gap.md),

                    // ====== ملاحظات ======
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes, size: 18),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ✅ رسالة الخطأ داخل النافذة
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: colors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18.sp, color: colors.error),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12.sp, color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) SizedBox(height: 8.h),
            // ====== الأزرار ======
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isSubmitting ||
                              _isCheckingDate ||
                              _targetSession == null)
                          ? null
                          : _submit,
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(widget.homework == null ? 'إضافة' : 'حفظ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

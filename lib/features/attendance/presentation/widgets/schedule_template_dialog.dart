import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/features/attendance/domain/entities/schedule_template_entity.dart';

class ScheduleTemplateDialog extends StatefulWidget {
  final int groupId;
  final ScheduleTemplateEntity? template;
  final Function(ScheduleTemplateEntity) onSubmit;

  const ScheduleTemplateDialog({
    super.key,
    required this.groupId,
    this.template,
    required this.onSubmit,
  });

  @override
  State<ScheduleTemplateDialog> createState() => _ScheduleTemplateDialogState();
}

class _ScheduleTemplateDialogState extends State<ScheduleTemplateDialog> {
  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _dayOfWeek = widget.template!.dayOfWeek;
      _startTime = TimeOfDay(
        hour: widget.template!.startTime.hour,
        minute: widget.template!.startTime.minute,
      );
      _endTime = TimeOfDay(
        hour: widget.template!.endTime.hour,
        minute: widget.template!.endTime.minute,
      );
      _locationController.text = widget.template!.location ?? '';
    } else {
      _dayOfWeek = 1; // الإثنين افتراضي
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
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
    // التحقق من الوقت
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وقت النهاية يجب أن يكون بعد وقت البداية'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final template = ScheduleTemplateEntity(
      id: widget.template?.id,
      groupId: widget.groupId,
      dayOfWeek: _dayOfWeek,
      startTime: DateTime(
        now.year,
        now.month,
        now.day,
        _startTime.hour,
        _startTime.minute,
      ),
      endTime: DateTime(
        now.year,
        now.month,
        now.day,
        _endTime.hour,
        _endTime.minute,
      ),
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      isActive: true,
    );

    widget.onSubmit(template);
    Navigator.of(context).pop();
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
                      Icons.schedule,
                      size: 20.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    widget.template == null
                        ? 'إضافة موعد أسبوعي'
                        : 'تعديل الموعد',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // اليوم
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'اليوم *',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('الأحد')),
                  DropdownMenuItem(value: 1, child: Text('الإثنين')),
                  DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
                  DropdownMenuItem(value: 3, child: Text('الأربعاء')),
                  DropdownMenuItem(value: 4, child: Text('الخميس')),
                  DropdownMenuItem(value: 5, child: Text('الجمعة')),
                  DropdownMenuItem(value: 6, child: Text('السبت')),
                ],
                onChanged: (value) => setState(() => _dayOfWeek = value ?? 1),
              ),
              SizedBox(height: 12.h),

              // الأوقات
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      borderRadius: BorderRadius.circular(10.r),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'من *',
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
                          labelText: 'إلى *',
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
              SizedBox(height: 12.h),

              // الموقع
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع (اختياري)',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: 16.h),

              // الأزرار
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
                      child: Text(widget.template == null ? 'إضافة' : 'حفظ'),
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

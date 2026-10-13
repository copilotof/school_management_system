import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_event.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_state.dart';
import 'package:school_management_system/injection_container.dart';

import '../../../../core/widgets/confirm_dialog.dart';

/// 📁 صفحة إدارة المعلمين

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeachersBloc>()..add(const FetchTeachers()),
      child: const TeachersView(),
    );
  }
}

class TeachersView extends StatelessWidget {
  const TeachersView({super.key});

  void _showAddDialog(BuildContext context, {TeacherEntity? teacher}) {
    showDialog(
      context: context,
      builder: (_) => _AddTeacherDialog(
        teacher: teacher,
        teachersBloc: context.read<TeachersBloc>(),
      ),
    );
  }

  Future<void> _deleteTeacher(
    BuildContext context,
    TeacherEntity teacher,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف المعلم "${teacher.fullName}"؟',
    );
    if (confirmed && context.mounted) {
      context.read<TeachersBloc>().add(DeleteTeacherEvent(teacher.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('المعلمون')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (query) {
                context.read<TeachersBloc>().add(SearchTeachersEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن معلم...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<TeachersBloc, TeachersState>(
              buildWhen: (prev, current) =>
                  prev.teachersState != current.teachersState,
              builder: (context, state) {
                return switch (state.teachersState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => const Center(child: Text('لا يوجد معلمون')),
                  Error(message: final msg) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(msg),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TeachersBloc>().add(
                              const FetchTeachers(),
                            );
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                  Success(data: final teachers) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.person_outline,
                              color: colors.primary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(teacher.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (teacher.specialization != null)
                                Text(teacher.specialization!),
                              if (teacher.phone != null) Text(teacher.phone!),
                            ],
                          ),
                          isThreeLine:
                              teacher.specialization != null &&
                              teacher.phone != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colors.primary,
                                ),
                                onPressed: () =>
                                    _showAddDialog(context, teacher: teacher),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                onPressed: () =>
                                    _deleteTeacher(context, teacher),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                };
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddTeacherDialog extends StatefulWidget {
  final TeacherEntity? teacher;
  final TeachersBloc teachersBloc;

  const _AddTeacherDialog({this.teacher, required this.teachersBloc});

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _specController;
  DateTime? _hireDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.teacher?.fullName ?? '',
    );
    _phoneController = TextEditingController(text: widget.teacher?.phone ?? '');
    _emailController = TextEditingController(text: widget.teacher?.email ?? '');
    _specController = TextEditingController(
      text: widget.teacher?.specialization ?? '',
    );
    _hireDate = widget.teacher?.hireDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'الاسم الكامل: حقل مطلوب');
      return;
    }

    final entity = TeacherEntity(
      id: widget.teacher?.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      specialization: _specController.text.trim().isEmpty
          ? null
          : _specController.text.trim(),
      hireDate: _hireDate,
      isActive: widget.teacher?.isActive ?? true,
    );

    if (widget.teacher == null) {
      widget.teachersBloc.add(CreateTeacherEvent(entity));
    } else {
      widget.teachersBloc.add(UpdateTeacherEvent(entity));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.teacher == null ? 'إضافة معلم' : 'تعديل معلم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل *'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'الهاتف'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _specController,
              decoration: const InputDecoration(labelText: 'التخصص'),
            ),
            SizedBox(height: 12.h),
            // تاريخ التوظيف
            InkWell(
              onTap: () async {
                final picked = await CustomDatePicker.showBottomSheet(
                  context: context,
                  initialDate: _hireDate ?? DateTime.now(),
                  minDate: DateTime(2000),
                  maxDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _hireDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ التوظيف',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _hireDate != null
                      ? DateFormat('yyyy/MM/dd').format(_hireDate!)
                      : 'اختر التاريخ',
                ),
              ),
            ),

            // ✅ رسالة الخطأ
            if (_errorMessage != null) ...[
              SizedBox(height: 12.h),
              Container(
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.teacher == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }
}

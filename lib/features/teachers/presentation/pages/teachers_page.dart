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
    final nameController = TextEditingController(text: teacher?.fullName ?? '');
    final phoneController = TextEditingController(text: teacher?.phone ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final specController = TextEditingController(
      text: teacher?.specialization ?? '',
    );
    DateTime? hireDate = teacher?.hireDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(teacher == null ? 'إضافة معلم' : 'تعديل معلم'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل *',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'الهاتف'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: specController,
                      decoration: const InputDecoration(labelText: 'التخصص'),
                    ),
                    SizedBox(height: 12.h),
                    // تاريخ التوظيف
                    InkWell(
                      onTap: () async {
                        final picked = await CustomDatePicker.showBottomSheet(
                          context: dialogContext,
                          initialDate: hireDate ?? DateTime.now(),
                          minDate: DateTime(2000),
                          maxDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => hireDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ التوظيف',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          hireDate != null
                              ? DateFormat('yyyy/MM/dd').format(hireDate!)
                              : 'اختر التاريخ',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;

                    final entity = TeacherEntity(
                      id: teacher?.id,
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      specialization: specController.text.trim().isEmpty
                          ? null
                          : specController.text.trim(),
                      hireDate: hireDate,
                      isActive: teacher?.isActive ?? true,
                    );

                    if (teacher == null) {
                      context.read<TeachersBloc>().add(
                        CreateTeacherEvent(entity),
                      );
                    } else {
                      context.read<TeachersBloc>().add(
                        UpdateTeacherEvent(entity),
                      );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(teacher == null ? 'إضافة' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلمون'),
        // automaticallyImplyLeading: false,
      ),
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
                        SizedBox(height: 8),
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
                                    _deleteTeacher(context, teacher),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                onPressed: () {
                                  context.read<TeachersBloc>().add(
                                    DeleteTeacherEvent(teacher.id!),
                                  );
                                },
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
}

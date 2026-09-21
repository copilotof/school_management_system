import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';

import '../../../subjects/presentation/bloc/subjects_state.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GradesBloc>().add(FetchGrades());
      context.read<SubjectsBloc>().add(const FetchSubjects());
    });

    return const GradesView();
  }
}

class GradesView extends StatelessWidget {
  const GradesView({super.key});

  void _showAddDialog(BuildContext context, {GradeEntity? grade}) {
    final gradesBloc = context.read<GradesBloc>();

    final nameController = TextEditingController(text: grade?.name ?? '');
    final orderController = TextEditingController(
      text: grade?.orderIndex.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(grade == null ? 'إضافة صف' : 'تعديل صف'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصف *',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الترتيب'),
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
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final entity = GradeEntity(
                      id: grade?.id,
                      levelId: null,
                      name: nameController.text.trim(),
                      orderIndex: int.tryParse(orderController.text) ?? 0,
                      isActive: grade?.isActive ?? true,
                    );
                    Navigator.of(dialogContext).pop();
                    if (grade == null) {
                      gradesBloc.add(CreateGradeEvent(entity));
                    } else {
                      gradesBloc.add(UpdateGradeEvent(entity));
                    }
                  },
                  child: Text(grade == null ? 'إضافة' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ✅ دالة إدارة المواد المرتبطة بالصف - مع BlocBuilder
  void _showManageSubjectsDialog(BuildContext context, GradeEntity grade) {
    final gradesBloc = context.read<GradesBloc>();

    // ✅ جلب المواد المرتبطة أولاً
    gradesBloc.add(FetchGradeSubjects(grade.id!));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<SubjectsBloc, SubjectsState>(
          builder: (dialogContext, subjectsState) {
            final allSubjects = subjectsState.subjectsState.data ?? [];

            if (allSubjects.isEmpty) {
              return AlertDialog(
                title: Text('مواد الصف: ${grade.name}'),
                content: const Text('لا توجد مواد. يرجى إضافة المواد أولاً.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              );
            }

            // ✅ استخدام BlocBuilder لمراقبة تغيرات gradeSubjectsState
            return BlocBuilder<GradesBloc, GradesState>(
              builder: (dialogContext, gradesState) {
                final linkedSubjects =
                    gradesState.gradeSubjectsState.data ?? [];
                final linkedIds = linkedSubjects.map((s) => s.id!).toSet();

                return _ManageSubjectsDialogContent(
                  grade: grade,
                  gradesBloc: gradesBloc,
                  subjects: allSubjects,
                  initialSelectedIds: linkedIds,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGrade(BuildContext context, GradeEntity grade) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف الصف "${grade.name}"؟',
    );
    if (confirmed && context.mounted) {
      context.read<GradesBloc>().add(DeleteGradeEvent(grade.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الصفوف الدراسية')),
      body: BlocBuilder<GradesBloc, GradesState>(
        builder: (context, state) {
          return switch (state.gradesState) {
            Initial() => const SizedBox.shrink(),
            Loading() => const Center(child: CircularProgressIndicator()),
            Empty() => const Center(child: Text('لا توجد صفوف')),
            Error(message: final msg) => Center(child: Text(msg)),
            Success(data: final grades) => ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                return _GradeCard(
                  grade: grade,
                  onEdit: () => _showAddDialog(context, grade: grade),
                  onDelete: () => _deleteGrade(context, grade),
                  onManageSubjects: () =>
                      _showManageSubjectsDialog(context, grade),
                );
              },
            ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_grade_fab',
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 📁 بطاقة صف - تصميم محسن
class _GradeCard extends StatelessWidget {
  final GradeEntity grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageSubjects;

  const _GradeCard({
    required this.grade,
    required this.onEdit,
    required this.onDelete,
    required this.onManageSubjects,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            // ====== رأس البطاقة ======
            Row(
              children: [
                // أيقونة الصف
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.class_outlined,
                    size: 22.sp,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                SizedBox(width: 10.w),
                // معلومات الصف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'الترتيب: ${grade.orderIndex}',
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
            SizedBox(height: 10.h),

            // ====== شريط الأزرار =====
            Row(
              children: [
                // ✅ زر رئيسي: إدارة المواد
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onManageSubjects,
                    icon: const Icon(Icons.book_outlined, size: 16),
                    label: const Text(
                      'ربط المواد',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.tertiary,
                      foregroundColor: colors.onTertiary,
                      minimumSize: Size(0, 34.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // زر تعديل
                _IconActionButton(
                  icon: Icons.edit_outlined,
                  color: colors.primary,
                  tooltip: 'تعديل',
                  onTap: onEdit,
                ),
                SizedBox(width: 6.w),
                // زر حذف
                _IconActionButton(
                  icon: Icons.delete_outline,
                  color: colors.error,
                  tooltip: 'حذف',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 زر أيقونة صغير
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: 34.w,
          height: 34.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 16.sp, color: color),
        ),
      ),
    );
  }
}

/// 📁 حوار إدارة المواد المرتبطة بالصف
class _ManageSubjectsDialog extends StatefulWidget {
  final GradeEntity grade;
  final GradesBloc gradesBloc;
  final List<SubjectEntity> subjects;

  const _ManageSubjectsDialog({
    required this.grade,
    required this.gradesBloc,
    required this.subjects,
  });

  @override
  State<_ManageSubjectsDialog> createState() => _ManageSubjectsDialogState();
}

class _ManageSubjectsDialogState extends State<_ManageSubjectsDialog> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    final linkedSubjects =
        widget.gradesBloc.state.gradeSubjectsState.data ?? [];
    _selectedIds = linkedSubjects.map((s) => s.id!).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('مواد الصف: ${widget.grade.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.subjects.map((subject) {
            return CheckboxListTile(
              title: Text(subject.name),
              value: _selectedIds.contains(subject.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(subject.id!);
                  } else {
                    _selectedIds.remove(subject.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.gradesBloc.add(
              SaveGradeSubjects(
                gradeId: widget.grade.id!,
                subjectIds: _selectedIds.toList(),
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

/// 📁 محتوى حوار إدارة المواد
class _ManageSubjectsDialogContent extends StatefulWidget {
  final GradeEntity grade;
  final GradesBloc gradesBloc;
  final List<SubjectEntity> subjects;
  final Set<int> initialSelectedIds;

  const _ManageSubjectsDialogContent({
    required this.grade,
    required this.gradesBloc,
    required this.subjects,
    required this.initialSelectedIds,
  });

  @override
  State<_ManageSubjectsDialogContent> createState() =>
      _ManageSubjectsDialogContentState();
}

class _ManageSubjectsDialogContentState
    extends State<_ManageSubjectsDialogContent> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    // ✅ نسخ القيم الأولية
    _selectedIds = Set<int>.from(widget.initialSelectedIds);
  }

  @override
  void didUpdateWidget(covariant _ManageSubjectsDialogContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ تحديث القيم إذا تغيرت من الـ Bloc
    if (oldWidget.initialSelectedIds != widget.initialSelectedIds) {
      _selectedIds = Set<int>.from(widget.initialSelectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('مواد الصف: ${widget.grade.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.subjects.map((subject) {
            return CheckboxListTile(
              title: Text(subject.name),
              value: _selectedIds.contains(subject.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(subject.id!);
                  } else {
                    _selectedIds.remove(subject.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.gradesBloc.add(
              SaveGradeSubjects(
                gradeId: widget.grade.id!,
                subjectIds: _selectedIds.toList(),
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

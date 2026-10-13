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

import '../../../../core/utils/translation_extension.dart';
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
    showDialog(
      context: context,
      builder: (_) =>
          _AddGradeDialog(grade: grade, gradesBloc: context.read<GradesBloc>()),
    );
  }

  void _showManageSubjectsDialog(BuildContext context, GradeEntity grade) {
    final gradesBloc = context.read<GradesBloc>();
    gradesBloc.add(FetchGradeSubjects(grade.id!));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<SubjectsBloc, SubjectsState>(
          builder: (dialogContext, subjectsState) {
            final allSubjects = subjectsState.subjectsState.data ?? [];

            if (allSubjects.isEmpty) {
              return AlertDialog(
                title: Text(context.tr('grades.manageSubjects')),
                content: Text(context.tr('grades.no_subjects')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.tr('common.close')),
                  ),
                ],
              );
            }

            return BlocBuilder<GradesBloc, GradesState>(
              builder: (dialogContext, gradesState) {
                final linkedSubjects =
                    gradesState.gradeSubjectsState.data ?? [];
                final linkedIds = linkedSubjects.map((s) => s.id!).toSet();

                return _ManageSubjectsDialog(
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
      title: context.tr('common.confirm'),
      message: context.tr(
        '${context.tr('dialogs.confirmDelete')} ${grade.name}"؟',
      ),
    );
    if (confirmed && context.mounted) {
      context.read<GradesBloc>().add(DeleteGradeEvent(grade.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('grades.title'))),
      body: BlocBuilder<GradesBloc, GradesState>(
        builder: (context, state) {
          return switch (state.gradesState) {
            Initial() => const SizedBox.shrink(),
            Loading() => const Center(child: CircularProgressIndicator()),
            Empty() => Center(child: Text(context.tr('grades.no_grades'))),
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

/// 📁 حوار إضافة أو تعديل الصف الدراسي
class _AddGradeDialog extends StatefulWidget {
  final GradeEntity? grade;
  final GradesBloc gradesBloc;

  const _AddGradeDialog({this.grade, required this.gradesBloc});

  @override
  State<_AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<_AddGradeDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.grade?.name ?? '');
    _orderController = TextEditingController(
      text: widget.grade?.orderIndex.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            '${context.tr('grades.name')}: ${context.tr('validators.required')}',
      );
      return;
    }

    final entity = GradeEntity(
      id: widget.grade?.id,
      levelId: null,
      name: _nameController.text.trim(),
      orderIndex: int.tryParse(_orderController.text) ?? 0,
      isActive: widget.grade?.isActive ?? true,
    );

    if (widget.grade == null) {
      widget.gradesBloc.add(CreateGradeEvent(entity));
    } else {
      widget.gradesBloc.add(UpdateGradeEvent(entity));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.grade == null
            ? context.tr('grades.add')
            : context.tr('grades.edit'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${context.tr('grades.name')} *',
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('grades.orderIndex'),
              ),
            ),
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
          child: Text(context.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(
            widget.grade == null
                ? context.tr('grades.add')
                : context.tr('common.save'),
          ),
        ),
      ],
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
            Row(
              children: [
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
                        '${context.tr('grades.orderIndex')}: ${grade.orderIndex}',
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onManageSubjects,
                    icon: const Icon(Icons.book_outlined, size: 16),
                    label: Text(
                      context.tr('grades.manageSubjects'),
                      style: TextStyle(
                        fontSize: 12.sp,
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
                _IconActionButton(
                  icon: Icons.edit_outlined,
                  color: colors.primary,
                  tooltip: context.tr('grades.edit'),
                  onTap: onEdit,
                ),
                SizedBox(width: 6.w),
                _IconActionButton(
                  icon: Icons.delete_outline,
                  color: colors.error,
                  tooltip: context.tr('grades.delete_grade'),
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

/// 📁 محتوى حوار إدارة المواد (مع دعم التحديث التلقائي)
class _ManageSubjectsDialog extends StatefulWidget {
  final GradeEntity grade;
  final GradesBloc gradesBloc;
  final List<SubjectEntity> subjects;
  final Set<int> initialSelectedIds;

  const _ManageSubjectsDialog({
    required this.grade,
    required this.gradesBloc,
    required this.subjects,
    required this.initialSelectedIds,
  });

  @override
  State<_ManageSubjectsDialog> createState() => _ManageSubjectsDialogState();
}

class _ManageSubjectsDialogState extends State<_ManageSubjectsDialog> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(widget.initialSelectedIds);
  }

  @override
  void didUpdateWidget(covariant _ManageSubjectsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedIds != widget.initialSelectedIds) {
      _selectedIds = Set<int>.from(widget.initialSelectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.tr(
          'grades.manageSubjects',
          params: {'grade_name': widget.grade.name},
        ),
      ),
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
          child: Text(context.tr('grades.cancel')),
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
          child: Text(context.tr('grades.save')),
        ),
      ],
    );
  }
}

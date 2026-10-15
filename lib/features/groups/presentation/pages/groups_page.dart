import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';
import 'package:school_management_system/features/groups/presentation/pages/group_details_page.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_event.dart';

import '../../../enrollment/presentation/pages/enrollment_page.dart';
import '../../../subjects/presentation/bloc/subjects_state.dart';
import '../../../teachers/presentation/bloc/teachers_state.dart';

import 'package:school_management_system/core/utils/translation_extension.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة إدارة الأفواج
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<GradesBloc>().add(FetchGrades());
      context.read<SubjectsBloc>().add(const FetchSubjects());
      context.read<TeachersBloc>().add(const FetchTeachers());
    });

    return const GroupsView();
  }
}

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  void _showAddDialog(BuildContext context, {GroupEntity? group}) {
    final groupsBloc = context.read<GroupsBloc>();
    final gradesBloc = context.read<GradesBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<GradesBloc, GradesState>(
          builder: (dialogContext, gradesState) {
            final grades = gradesState.gradesState.data ?? [];

            if (grades.isEmpty) {
              return AlertDialog(
                title: Text(context.tr('dialogs.alert')),
                content: Text(context.tr('groups.noGrades')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.tr('common.ok')),
                  ),
                ],
              );
            }

            return BlocBuilder<SubjectsBloc, SubjectsState>(
              builder: (dialogContext, subjectsState) {
                final subjects = subjectsState.subjectsState.data ?? [];

                return BlocBuilder<TeachersBloc, TeachersState>(
                  builder: (dialogContext, teachersState) {
                    final teachers = teachersState.teachersState.data ?? [];

                    return _AddGroupDialog(
                      group: group,
                      grades: grades,
                      subjects: subjects,
                      teachers: teachers,
                      groupsBloc: groupsBloc,
                      gradesBloc: gradesBloc,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGroup(BuildContext context, GroupEntity group) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: context.tr('groups.deleteTitle'),
      message: '${context.tr('groups.deleteMessage')} "${group.name}"؟',
    );
    if (confirmed && context.mounted) {
      context.read<GroupsBloc>().add(DeleteGroupEvent(group.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('groups.title'))),
      body: Column(
        children: [
          // ====== بطاقة البحث ======
          Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
            ),
            child: TextField(
              onChanged: (query) {
                context.read<GroupsBloc>().add(SearchGroupsEvent(query));
              },
              decoration: InputDecoration(
                hintText: context.tr('groups.searchHint'),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),

          // ====== قائمة الأفواج ======
          Expanded(
            child: BlocBuilder<GroupsBloc, GroupsState>(
              buildWhen: (prev, current) =>
                  prev.groupsState != current.groupsState,
              builder: (context, state) {
                return switch (state.groupsState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => Center(child: Text(context.tr('groups.empty'))),
                  Error(message: final msg) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(msg),
                        SizedBox(height: 8.h),
                        ElevatedButton(
                          onPressed: () => context.read<GroupsBloc>().add(
                            const FetchGroups(),
                          ),
                          child: Text(context.tr('groups.retry')),
                        ),
                      ],
                    ),
                  ),
                  Success(data: final groups) => ListView.builder(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 80.h),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _GroupCard(
                        group: group,
                        onEdit: () => _showAddDialog(context, group: group),
                        onDelete: () => _deleteGroup(context, group),
                        onDetails: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupDetailsPage(group: group),
                            ),
                          );
                        },
                        // ✅ جديد
                        onManageStudents: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EnrollmentPage(initialGroupId: group.id),
                            ),
                          );
                        },
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
        heroTag: 'add_group_fab',
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 📁 بطاقة فوج
/// 📁 بطاقة فوج - تصميم محسن
class _GroupCard extends StatelessWidget {
  final GroupEntity group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  final VoidCallback onManageStudents; // ✅ جديد

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
    required this.onManageStudents, // ✅
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
            InkWell(
              onTap: onDetails,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.groups,
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
                            group.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${context.tr('groups.monthlyFee')}: ${group.monthlyFee.toStringAsFixed(0)} ${context.tr('common.currency')}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      size: 22.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // ====== شريط الأزرار =====
            Row(
              children: [
                // ✅ زر عرض التفاصيل (رئيسي)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: Text(
                      context.tr('groups.details'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 34.h),
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),

                // ✅ زر إدارة الطلبة (جديد)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onManageStudents,
                    icon: const Icon(Icons.person_add_outlined, size: 14),
                    label: Text(
                      context.tr('groups.manageStudents'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      minimumSize: Size(0, 34.h),
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
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
                  tooltip: context.tr('common.edit'),
                  onTap: onEdit,
                ),
                SizedBox(width: 6.w),

                // زر حذف
                _IconActionButton(
                  icon: Icons.delete_outline,
                  color: colors.error,
                  tooltip: context.tr('common.delete'),
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

/// 📁 حوار إضافة/تعديل فوج
class _AddGroupDialog extends StatefulWidget {
  final GroupEntity? group;
  final List<GradeEntity> grades;
  final List<SubjectEntity> subjects;
  final List<TeacherEntity> teachers;
  final GroupsBloc groupsBloc;
  final GradesBloc gradesBloc;

  const _AddGroupDialog({
    this.group,
    required this.grades,
    required this.subjects,
    required this.teachers,
    required this.groupsBloc,
    required this.gradesBloc,
  });

  @override
  State<_AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<_AddGroupDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _feeController;
  late final TextEditingController _maxStudentsController;

  int? _selectedGradeId;
  int? _selectedSubjectId;
  int? _selectedTeacherId;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _feeController = TextEditingController(
      text: widget.group?.monthlyFee.toString() ?? '',
    );
    _maxStudentsController = TextEditingController(
      text: widget.group?.maxStudents.toString() ?? '',
    );
    _selectedGradeId = widget.group?.gradeId;
    _selectedSubjectId = widget.group?.subjectId;
    _selectedTeacherId = widget.group?.teacherId;

    if (_selectedGradeId != null) {
      widget.gradesBloc.add(FetchGradeSubjects(_selectedGradeId!));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  List<SubjectEntity> get _filteredSubjects {
    if (_selectedGradeId == null) return [];
    final gradeSubjects = widget.gradesBloc.state.gradeSubjectsState.data ?? [];
    final subjectIds = gradeSubjects.map((s) => s.id).toSet();
    return widget.subjects.where((s) => subjectIds.contains(s.id)).toList();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('validators.required'));
      return;
    }
    if (_selectedGradeId == null) {
      setState(
        () => _errorMessage =
            '${context.tr('groups.grade')}: ${context.tr('validators.required')}',
      );
      return;
    }
    if (_selectedSubjectId == null) {
      setState(
        () => _errorMessage =
            '${context.tr('groups.subject')}: ${context.tr('validators.required')}',
      );
      return;
    }
    if (_feeController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            '${context.tr('groups.monthlyFee')}: ${context.tr('validators.required')}',
      );
      return;
    }

    final entity = GroupEntity(
      id: widget.group?.id,
      name: _nameController.text.trim(),
      subjectId: _selectedSubjectId,
      teacherId: _selectedTeacherId,
      academicLevelId: null,
      gradeId: _selectedGradeId,
      maxStudents: int.tryParse(_maxStudentsController.text) ?? 30,
      monthlyFee: double.tryParse(_feeController.text) ?? 0,
      isActive: widget.group?.isActive ?? true,
    );

    if (widget.group == null) {
      widget.groupsBloc.add(CreateGroupEvent(entity));
    } else {
      widget.groupsBloc.add(UpdateGroupEvent(entity));
    }

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
                      Icons.groups,
                      size: 20.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    widget.group == null
                        ? context.tr('groups.add')
                        : context.tr('groups.edit'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Gap.lg),

              // اسم الفوج
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${context.tr('groups.name')} *',
                  prefixIcon: Icon(Icons.groups_outlined, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.md),

              // الصف
              DropdownButtonFormField<int>(
                initialValue: _selectedGradeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '${context.tr('groups.grade')} *',
                  prefixIcon: Icon(Icons.class_outlined, size: 18),
                  isDense: true,
                ),
                items: widget.grades.map((grade) {
                  return DropdownMenuItem(
                    value: grade.id,
                    child: Text(grade.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGradeId = value;
                    _selectedSubjectId = null;
                  });
                  if (value != null) {
                    widget.gradesBloc.add(FetchGradeSubjects(value));
                  }
                },
              ),
              SizedBox(height: _Gap.md),

              // المادة (فقط مواد الصف)
              if (_selectedGradeId == null)
                Text(
                  context.tr('groups.selectGradeFirst'),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                BlocBuilder<GradesBloc, GradesState>(
                  builder: (context, gradesState) {
                    final filtered = _filteredSubjects;
                    if (filtered.isEmpty) {
                      return Text(
                        context.tr('groups.noSubjectsAvailable'),
                        style: TextStyle(fontSize: 11.sp, color: colors.error),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedSubjectId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: '${context.tr('groups.subject')} *',
                        prefixIcon: Icon(Icons.book_outlined, size: 18),
                        isDense: true,
                      ),
                      items: filtered.map((subject) {
                        return DropdownMenuItem(
                          value: subject.id,
                          child: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSubjectId = value),
                    );
                  },
                ),
              SizedBox(height: _Gap.md),

              // الرسوم
              TextField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      '${context.tr('groups.monthlyFee')} (${context.tr('common.currency')}) *',
                  prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.md),

              // المعلم (اختياري)
              DropdownButtonFormField<int>(
                initialValue: _selectedTeacherId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText:
                      '${context.tr('groups.teacher')} (${context.tr('common.optional')})',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.tr('groups.noTeacher')),
                  ),
                  ...widget.teachers.map((teacher) {
                    return DropdownMenuItem(
                      value: teacher.id,
                      child: Text(
                        teacher.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) =>
                    setState(() => _selectedTeacherId = value),
              ),
              SizedBox(height: _Gap.md),

              // الطاقة الاستيعابية
              TextField(
                controller: _maxStudentsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      '${context.tr('groups.maxStudents')} (${context.tr('common.optional')})',
                  prefixIcon: Icon(Icons.people_outline, size: 18),
                  isDense: true,
                ),
              ),
              SizedBox(height: _Gap.lg),

              if (_errorMessage != null) ...[
                SizedBox(height: _Gap.md),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: colors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18.sp,
                        color: colors.error,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colors.error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16.sp),
                        onPressed: () => setState(() => _errorMessage = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],

              // أزرار
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.tr('groups.cancel')),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        widget.group == null
                            ? context.tr('groups.add')
                            : context.tr('groups.save'),
                      ),
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

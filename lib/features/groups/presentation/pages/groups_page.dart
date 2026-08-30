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
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_event.dart';

import '../../../subjects/presentation/bloc/subjects_state.dart';
import '../../../teachers/presentation/bloc/teachers_state.dart';
import 'group_details_page.dart';

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
                title: const Text('تنبيه'),
                content: const Text(
                  'لا توجد صفوف. يرجى إضافة الصفوف أولاً من صفحة الصفوف الدراسية.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              );
            }

            return BlocBuilder<SubjectsBloc, SubjectsState>(
              builder: (dialogContext, subjectsState) {
                final subjects = subjectsState.subjectsState.data ?? [];

                if (subjects.isEmpty) {
                  return AlertDialog(
                    title: const Text('تنبيه'),
                    content: const Text(
                      'لا توجد مواد. يرجى إضافة المواد أولاً من صفحة المواد الدراسية.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('حسناً'),
                      ),
                    ],
                  );
                }

                return BlocBuilder<TeachersBloc, TeachersState>(
                  builder: (dialogContext, teachersState) {
                    final teachers = teachersState.teachersState.data ?? [];

                    return _AddGroupDialog(
                      group: group,
                      grades: grades,
                      subjects: subjects,
                      teachers: teachers,
                      groupsBloc: groupsBloc,
                      gradesBloc: gradesBloc, // ✅ نمرر GradesBloc
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
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف الفوج "${group.name}"؟',
    );
    if (confirmed && context.mounted) {
      context.read<GroupsBloc>().add(DeleteGroupEvent(group.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الأفواج')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (query) {
                context.read<GroupsBloc>().add(SearchGroupsEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن فوج...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<GroupsBloc, GroupsState>(
              buildWhen: (prev, current) =>
                  prev.groupsState != current.groupsState,
              builder: (context, state) {
                return switch (state.groupsState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => const Center(
                    child: Text('لا توجد أفواج. اضغط + لإضافة فوج.'),
                  ),
                  Error(message: final msg) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(msg),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GroupsBloc>().add(const FetchGroups());
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                  Success(data: final groups) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _GroupCard(
                        group: group,
                        onEdit: () => _showAddDialog(context, group: group),
                        onDelete: () => _deleteGroup(context, group),
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

/// ✅ بطاقة فوج محسنة
class _GroupCard extends StatelessWidget {
  final GroupEntity group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.secondary.withOpacity(0.1),
          child: Icon(
            Icons.groups_outlined,
            color: colors.secondary,
            size: 20.sp,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('الرسوم: ${group.monthlyFee.toStringAsFixed(0)} دج'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: colors.primary,
                size: 20.sp,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colors.error,
                size: 20.sp,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroupDetailsPage(group: group)),
          );
        },
      ),
    );
  }
}

/// ✅ حوار إضافة فوج - مع GradesBloc
class _AddGroupDialog extends StatefulWidget {
  final GroupEntity? group;
  final List<GradeEntity> grades;
  final List<SubjectEntity> subjects;
  final List<TeacherEntity> teachers;
  final GroupsBloc groupsBloc;
  final GradesBloc gradesBloc; // ✅

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

    // ✅ جلب المواد المرتبطة بالصف عند التعديل
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

  /// ✅ المواد التابعة للصف المختار
  List<SubjectEntity> get _filteredSubjects {
    if (_selectedGradeId == null) return [];
    final gradeSubjects = widget.gradesBloc.state.gradeSubjectsState.data ?? [];
    final subjectIds = gradeSubjects.map((s) => s.id).toSet();
    return widget.subjects.where((s) => subjectIds.contains(s.id)).toList();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    if (_selectedGradeId == null) return;
    if (_selectedSubjectId == null) return;
    if (_feeController.text.trim().isEmpty) return;

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
    return AlertDialog(
      title: Text(widget.group == null ? 'إضافة فوج' : 'تعديل فوج'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. اسم الفوج (إجباري)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفوج *',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
            ),
            SizedBox(height: 12.h),

            // 2. الصف (إجباري)
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _selectedGradeId,
              decoration: const InputDecoration(
                labelText: 'الصف *',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: widget.grades.map((grade) {
                return DropdownMenuItem(
                  value: grade.id,
                  child: Text(
                    grade.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
            SizedBox(height: 12.h),

            // 3. المادة (إجباري - تظهر فقط مواد الصف)
            if (_selectedGradeId == null)
              const Text(
                'اختر الصف أولاً لعرض المواد',
                style: TextStyle(color: Colors.grey),
              )
            else
              BlocBuilder<GradesBloc, GradesState>(
                builder: (context, gradesState) {
                  final filtered = _filteredSubjects;
                  if (filtered.isEmpty) {
                    return const Text(
                      'لا توجد مواد مرتبطة بهذا الصف. يرجى ربط المواد بالصف أولاً.',
                      style: TextStyle(color: Colors.orange),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'المادة *',
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                    items: filtered.map((subject) {
                      return DropdownMenuItem(
                        value: subject.id,
                        child: Text(
                          subject.name,
                          overflow: TextOverflow.ellipsis, // ✅
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubjectId = value);
                    },
                  );
                },
              ),
            SizedBox(height: 12.h),

            // 4. الرسوم الشهرية (إجباري)
            TextField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرسوم الشهرية (دج) *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            SizedBox(height: 12.h),

            // 5. المعلم (اختياري)
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _selectedTeacherId,
              decoration: const InputDecoration(
                labelText: 'المعلم (اختياري)',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون معلم')),
                ...widget.teachers.map((teacher) {
                  return DropdownMenuItem(
                    value: teacher.id,
                    child: Text(
                      teacher.fullName,
                      overflow: TextOverflow.ellipsis, // ✅
                      maxLines: 1,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedTeacherId = value);
              },
            ),
            SizedBox(height: 12.h),

            // 6. الطاقة الاستيعابية (اختياري)
            TextField(
              controller: _maxStudentsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الطاقة الاستيعابية (اختياري)',
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
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
          child: Text(widget.group == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }
}

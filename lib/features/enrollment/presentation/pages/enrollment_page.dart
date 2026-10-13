import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';

import '../../../../core/utils/translation_extension.dart';
import '../../../../core/widgets/custom_date_picker.dart';
import '../../../groups/presentation/bloc/groups_state.dart';
import '../../../students/presentation/bloc/students_state.dart';

/// 📁 صفحة تسجيل الطلاب في الأفواج - مع تاريخ التسجيل

class EnrollmentPage extends StatefulWidget {
  final int? initialGroupId;

  const EnrollmentPage({super.key, this.initialGroupId});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  int? _selectedGroupId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GroupsBloc>().add(const FetchGroups());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentEntity> _filterStudents(List<StudentEntity> students) {
    if (_searchQuery.isEmpty) return students;
    final query = _searchQuery.toLowerCase();
    return students.where((student) {
      return student.fullName.toLowerCase().contains(query) ||
          student.studentCode.toLowerCase().contains(query);
    }).toList();
  }

  /// ✅ تسجيل طالب مع تاريخ التسجيل
  void _enrollStudent(StudentEntity student) {
    if (_selectedGroupId == null) return;

    // ✅ فتح حوار اختيار تاريخ التسجيل
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _EnrollmentDateDialog(
          student: student,
          groupId: _selectedGroupId!,
          enrollmentBloc: context.read<EnrollmentBloc>(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('enrollment.title'))),
      body: Column(
        children: [
          // ====== اختيار الفوج ======
          Padding(
            padding: const EdgeInsets.all(12),
            child: BlocBuilder<GroupsBloc, GroupsState>(
              builder: (context, groupsState) {
                final groups = groupsState.groupsState.data ?? [];

                if (groups.isEmpty) {
                  return Card(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد أفواج. يرجى إضافة الأفواج أولاً.',
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selectedGroupId,
                  decoration: InputDecoration(
                    labelText: context.tr('enrollment.selectGroup'),
                    prefixIcon: const Icon(Icons.groups_outlined),
                  ),
                  items: groups.map((group) {
                    return DropdownMenuItem(
                      value: group.id,
                      child: Text(
                        group.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
            ),
          ),

          // ====== حقل البحث ======
          if (_selectedGroupId != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: context.tr('enrollment.searchStudent'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
          Expanded(
            child: _selectedGroupId == null
                ? const Center(child: Text('اختر فوجاً أولاً'))
                : _buildStudentList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, enrollmentState) {
        return BlocBuilder<StudentsBloc, StudentsState>(
          builder: (context, studentsState) {
            final allStudents = studentsState.studentsState.data ?? [];
            final enrollments = enrollmentState.enrollmentsState.data ?? [];

            final filteredAllStudents = _filterStudents(allStudents);

            final enrolledStudentIds = enrollments
                .where(
                  (e) => e.groupId == _selectedGroupId && e.status == 'active',
                )
                .map((e) => e.studentId)
                .toSet();

            final availableStudents = filteredAllStudents
                .where((s) => !enrolledStudentIds.contains(s.id))
                .toList();

            final enrolledStudents = filteredAllStudents
                .where((s) => enrolledStudentIds.contains(s.id))
                .toList();

            // ✅ الحصول على تواريخ التسجيل لكل طالب مسجل
            Map<int, DateTime> enrollmentDates = {};
            for (final enrollment in enrollments.where(
              (e) => e.groupId == _selectedGroupId,
            )) {
              enrollmentDates[enrollment.studentId] = enrollment.enrollmentDate;
            }

            if (filteredAllStudents.isEmpty) {
              return Center(child: Text(context.tr('enrollment.noResults')));
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ====== قسم المسجلين ======
                if (enrolledStudents.isNotEmpty) ...[
                  _SectionHeader(
                    title:
                        '${context.tr('enrollment.enrolledStudents')} (${enrolledStudents.length})',
                    icon: Icons.check_circle,
                    color: colors.secondary,
                  ),
                  ...enrolledStudents.map((student) {
                    final enrollmentDate = enrollmentDates[student.id];
                    return _StudentCard(
                      student: student,
                      isEnrolled: true,
                      enrollmentDate: enrollmentDate,
                      onToggle: () => _removeStudent(student),
                    );
                  }),
                  SizedBox(height: 16.h),
                ],

                // ====== قسم المتاحين ======
                if (availableStudents.isNotEmpty) ...[
                  _SectionHeader(
                    title:
                        '${context.tr('enrollment.availableStudents')} (${availableStudents.length})',
                    icon: Icons.person_add,
                    color: colors.primary,
                  ),
                  ...availableStudents.map(
                    (student) => _StudentCard(
                      student: student,
                      isEnrolled: false,
                      enrollmentDate: null,
                      onToggle: () => _enrollStudent(student),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _removeStudent(StudentEntity student) {
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final enrollment = enrollments
        .where(
          (e) => e.studentId == student.id && e.groupId == _selectedGroupId,
        )
        .firstOrNull;

    if (enrollment == null) return;

    context.read<EnrollmentBloc>().add(DeleteEnrollmentEvent(enrollment.id!));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr('enrollment.unenrolledSuccess')}: ${student.fullName}',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// 📁 حوار اختيار تاريخ التسجيل
class _EnrollmentDateDialog extends StatefulWidget {
  final StudentEntity student;
  final int groupId;
  final EnrollmentBloc enrollmentBloc;

  const _EnrollmentDateDialog({
    required this.student,
    required this.groupId,
    required this.enrollmentBloc,
  });

  @override
  State<_EnrollmentDateDialog> createState() => _EnrollmentDateDialogState();
}

class _EnrollmentDateDialogState extends State<_EnrollmentDateDialog> {
  DateTime _selectedDate = DateTime.now();

  void _submit() {
    final enrollment = EnrollmentEntity(
      studentId: widget.student.id!,
      groupId: widget.groupId,
      enrollmentDate: _selectedDate,
      registrationFee: 0,
      status: 'active',
    );

    widget.enrollmentBloc.add(CreateEnrollmentEvent(enrollment));

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr('enrollment.enrolledSuccess')}: ${widget.student.fullName}',
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${context.tr('enrollment.enroll')}: ${widget.student.fullName}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('enrollment.enrollDate')),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () async {
              final picked = await CustomDatePicker.showBottomSheet(
                context: context,
                initialDate: _selectedDate,
                minDate: DateTime(DateTime.now().year - 1),
                maxDate: DateTime(DateTime.now().year + 1),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              child: Text(
                DateFormat('yyyy/MM/dd').format(_selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.tr('enrollment.enroll')),
        ),
      ],
    );
  }
}

/// 📁 بطاقة طالب - مع تاريخ التسجيل
class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  final bool isEnrolled;
  final DateTime? enrollmentDate;
  final VoidCallback onToggle;

  const _StudentCard({
    required this.student,
    required this.isEnrolled,
    required this.onToggle,
    this.enrollmentDate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isEnrolled ? colors.secondary : colors.primary)
              .withOpacity(0.1),
          child: Text(
            student.firstName.isNotEmpty
                ? student.firstName.substring(0, 1)
                : '؟',
            style: TextStyle(
              color: isEnrolled ? colors.secondary : colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('students.studentCode')}: ${student.studentCode}',
            ),
            // ✅ عرض تاريخ التسجيل للمسجلين
            if (isEnrolled && enrollmentDate != null)
              Text(
                '${context.tr('groups.enrollmentDate')}: ${DateFormat('yyyy/MM/dd').format(enrollmentDate!)}',
                style: TextStyle(fontSize: 11.sp, color: colors.secondary),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: (isEnrolled ? colors.error : colors.secondary).withOpacity(
                0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnrolled ? Icons.remove : Icons.add,
              color: isEnrolled ? colors.error : colors.secondary,
              size: 20.sp,
            ),
          ),
          tooltip: isEnrolled
              ? context.tr('enrollment.unenroll')
              : context.tr('enrollment.enroll'),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

/// 📁 رأس قسم
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

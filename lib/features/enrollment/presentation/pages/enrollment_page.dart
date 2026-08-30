import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';

import '../../../groups/presentation/bloc/groups_state.dart';
import '../../../students/presentation/bloc/students_state.dart';

/// 📁 صفحة تسجيل الطلاب في الأفواج - مع البحث

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

  /// ✅ تصفية الطلاب حسب البحث
  List<StudentEntity> _filterStudents(List<StudentEntity> students) {
    if (_searchQuery.isEmpty) return students;
    final query = _searchQuery.toLowerCase();
    return students.where((student) {
      return student.fullName.toLowerCase().contains(query) ||
          student.studentCode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الطلاب في الأفواج')),
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
                    labelText: 'اختر الفوج *',
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
                  hintText: 'ابحث عن طالب بالاسم أو الرقم...',
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

  /// ✅ بناء قائمة الطلاب مع البحث
  Widget _buildStudentList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, enrollmentState) {
        return BlocBuilder<StudentsBloc, StudentsState>(
          builder: (context, studentsState) {
            final allStudents = studentsState.studentsState.data ?? [];
            final enrollments = enrollmentState.enrollmentsState.data ?? [];

            // ✅ تطبيق البحث أولاً
            final filteredAllStudents = _filterStudents(allStudents);

            // الطلاب المسجلون في هذا الفوج
            final enrolledStudentIds = enrollments
                .where(
                  (e) => e.groupId == _selectedGroupId && e.status == 'active',
                )
                .map((e) => e.studentId)
                .toSet();

            // الطلاب غير المسجلين (مع البحث)
            final availableStudents = filteredAllStudents
                .where((s) => !enrolledStudentIds.contains(s.id))
                .toList();

            // الطلاب المسجلون (مع البحث)
            final enrolledStudents = filteredAllStudents
                .where((s) => enrolledStudentIds.contains(s.id))
                .toList();

            if (filteredAllStudents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48.sp,
                      color: colors.onSurfaceVariant,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _searchQuery.isEmpty
                          ? 'لا يوجد طلاب'
                          : 'لا توجد نتائج للبحث "${_searchQuery}"',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ====== قسم المسجلين ======
                if (enrolledStudents.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'الطلاب المسجلون (${enrolledStudents.length})',
                    icon: Icons.check_circle,
                    color: colors.secondary,
                  ),
                  ...enrolledStudents.map(
                    (student) => _StudentCard(
                      student: student,
                      isEnrolled: true,
                      onToggle: () => _removeStudent(student),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // ====== قسم المتاحين ======
                if (availableStudents.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'الطلاب المتاحون (${availableStudents.length})',
                    icon: Icons.person_add,
                    color: colors.primary,
                  ),
                  ...availableStudents.map(
                    (student) => _StudentCard(
                      student: student,
                      isEnrolled: false,
                      onToggle: () => _enrollStudent(student),
                    ),
                  ),
                ],

                // ====== إذا الجميع مسجلون ======
                if (availableStudents.isEmpty &&
                    enrolledStudents.isNotEmpty &&
                    _searchQuery.isEmpty) ...[
                  SizedBox(height: 40.h),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48.sp,
                          color: colors.secondary,
                        ),
                        SizedBox(height: 8.h),
                        Text('كل الطلاب مسجلون في هذا الفوج'),
                      ],
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

  /// ✅ تسجيل طالب
  void _enrollStudent(StudentEntity student) {
    if (_selectedGroupId == null) return;

    final enrollment = EnrollmentEntity(
      studentId: student.id!,
      groupId: _selectedGroupId!,
      enrollmentDate: DateTime.now(),
      registrationFee: 0,
      status: 'active',
    );

    context.read<EnrollmentBloc>().add(CreateEnrollmentEvent(enrollment));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل ${student.fullName} بنجاح'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// ✅ إلغاء تسجيل طالب
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
        content: Text('تم إلغاء تسجيل ${student.fullName}'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 1),
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

/// 📁 بطاقة طالب
class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  final bool isEnrolled;
  final VoidCallback onToggle;

  const _StudentCard({
    required this.student,
    required this.isEnrolled,
    required this.onToggle,
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
        subtitle: Text('الرقم: ${student.studentCode}'),
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
          tooltip: isEnrolled ? 'إلغاء التسجيل' : 'تسجيل في الفوج',
          onPressed: onToggle,
        ),
      ),
    );
  }
}

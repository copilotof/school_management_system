import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/students/presentation/pages/add_student_page.dart';
import 'package:school_management_system/features/students/presentation/pages/edit_student_page.dart';
import 'package:school_management_system/features/students/presentation/pages/student_details_page.dart';
import 'package:school_management_system/injection_container.dart';

import 'students_qr_print_page.dart';

// ============================================================
// 🎨 ثوابت التصميم الموحدة
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة إدارة الطلاب
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentsBloc>()..add(const FetchStudents()),
      child: const StudentsView(),
    );
  }
}

class StudentsView extends StatelessWidget {
  const StudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'طباعة رموز QR',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StudentsQrPrintPage()),
              );
            },
          ),
        ],
      ),
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
                context.read<StudentsBloc>().add(SearchStudentsEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن طالب بالاسم أو الرقم...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    context.read<StudentsBloc>().add(const FetchStudents());
                  },
                ),
              ),
            ),
          ),

          // ====== قائمة الطلاب ======
          Expanded(
            child: BlocBuilder<StudentsBloc, StudentsState>(
              buildWhen: (previous, current) =>
                  previous.studentsState != current.studentsState,
              builder: (context, state) {
                return switch (state.studentsState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => _EmptyStudents(colors: colors),
                  Error(message: final msg) => _ErrorStudents(
                    message: msg,
                    colors: colors,
                    onRetry: () {
                      context.read<StudentsBloc>().add(const FetchStudents());
                    },
                  ),
                  Success(data: final students) => _StudentsList(
                    students: students,
                  ),
                };
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_student_fab',
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddStudentPage()),
          );
          if (result == true && context.mounted) {
            context.read<StudentsBloc>().add(const FetchStudents());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 📁 قائمة الطلاب
class _StudentsList extends StatelessWidget {
  final List<StudentEntity> students;
  const _StudentsList({required this.students});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 80.h),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentCard(student: student);
      },
    );
  }
}

/// 📁 بطاقة طالب - تصميم موحد
class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: colors.primaryContainer,
          child: Text(
            student.firstName.isNotEmpty
                ? student.firstName.substring(0, 1)
                : '؟',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'الرقم: ${student.studentCode}',
          style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 18.sp,
                color: colors.primary,
              ),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditStudentPage(student: student),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<StudentsBloc>().add(const FetchStudents());
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18.sp,
                color: colors.error,
              ),
              onPressed: () {
                _showDeleteDialog(context, student);
              },
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => StudentDetailsPage(student: student),
            ),
          );
          if (result == true && context.mounted) {
            context.read<StudentsBloc>().add(const FetchStudents());
          }
        },
      ),
    );
  }

  /// حوار تأكيد الحذف
  void _showDeleteDialog(BuildContext context, StudentEntity student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الطالب ${student.fullName}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<StudentsBloc>().add(DeleteStudentEvent(student.id!));
    }
  }
}

/// 📁 حالة فارغة
class _EmptyStudents extends StatelessWidget {
  final ColorScheme colors;
  const _EmptyStudents({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 48.sp,
              color: colors.onPrimaryContainer,
            ),
          ),
          SizedBox(height: _Gap.md),
          Text(
            'لا يوجد طلاب مسجلون',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: _Gap.xs),
          Text(
            'اضغط على + لإضافة طالب جديد',
            style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 📁 حالة خطأ
class _ErrorStudents extends StatelessWidget {
  final String message;
  final ColorScheme colors;
  final VoidCallback onRetry;

  const _ErrorStudents({
    required this.message,
    required this.colors,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48.sp,
              color: colors.onErrorContainer,
            ),
          ),
          SizedBox(height: _Gap.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: colors.onSurfaceVariant),
          ),
          SizedBox(height: _Gap.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(minimumSize: Size(150.w, 40.h)),
          ),
        ],
      ),
    );
  }
}

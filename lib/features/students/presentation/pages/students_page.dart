import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/students/presentation/pages/add_student_page.dart';
import 'package:school_management_system/features/students/presentation/pages/edit_student_page.dart';
import 'package:school_management_system/injection_container.dart';

import 'student_details_page.dart';

/// 📁 صفحة إدارة الطلاب - النسخة النهائية

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
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (query) {
                context.read<StudentsBloc>().add(SearchStudentsEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن طالب...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    context.read<StudentsBloc>().add(const FetchStudents());
                  },
                ),
              ),
            ),
          ),
          // قائمة الطلاب
          Expanded(
            child: BlocBuilder<StudentsBloc, StudentsState>(
              buildWhen: (previous, current) =>
                  previous.studentsState != current.studentsState,
              builder: (context, state) {
                return switch (state.studentsState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => const _EmptyStudents(),
                  Error(message: final msg) => _ErrorStudents(
                    message: msg,
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
        onPressed: () async {
          // ✅ فتح صفحة الإضافة
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddStudentPage()),
          );
          // إذا تمت الإضافة بنجاح، أعد تحميل القائمة
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
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentCard(student: student);
      },
    );
  }
}

/// 📁 بطاقة طالب
class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primary.withOpacity(0.1),
          child: Text(
            student.firstName.isNotEmpty
                ? student.firstName.substring(0, 1)
                : '؟',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Text('الرقم: ${student.studentCode}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التعديل
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colors.primary),
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
            // زر الحذف
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
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

  /// إظهار حوار تأكيد الحذف
  Future<void> _showDeleteDialog(
    BuildContext context,
    StudentEntity student,
  ) async {
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
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'لا يوجد طلاب مسجلون',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 📁 حالة خطأ
class _ErrorStudents extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorStudents({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

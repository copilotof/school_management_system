import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/students/presentation/pages/add_student_page.dart';
import 'package:school_management_system/features/students/presentation/pages/edit_student_page.dart';
import 'package:school_management_system/features/students/presentation/pages/student_details_page.dart';
import 'package:school_management_system/features/students/presentation/pages/students_qr_print_page.dart';
import 'package:school_management_system/injection_container.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

class _Radius {
  static double get card => 12.r;
  static double get item => 10.r;
}

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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('students.title')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: context.tr('students.printQrCodes'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StudentsQrPrintPage(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildSearchBar(context),
          const Expanded(child: _StudentsBody()),
        ],
      ),
      floatingActionButton: const _AddStudentButton(),
    );
  }

  /// بطاقة البحث — خارج BlocBuilder حتى لا تُعاد بناؤها مع كل تغيّر حالة
  Widget _buildSearchBar(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_Radius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: const _StudentSearchField(),
    );
  }
}

/// 📁 حقل البحث مع تأخير (debounce)
///
/// ✅ يمنع تنفيذ استعلام قاعدة بيانات مع كل حرف يكتبه المستخدم — ينفّذه بعد
/// توقّفه عن الكتابة فقط، فيزول التقطيع أثناء الكتابة في القوائم الكبيرة.
class _StudentSearchField extends StatefulWidget {
  const _StudentSearchField();

  @override
  State<_StudentSearchField> createState() => _StudentSearchFieldState();
}

class _StudentSearchFieldState extends State<_StudentSearchField> {
  /// مدة الانتظار بعد آخر حرف
  static const Duration _debounceDelay = Duration(milliseconds: 350);

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      context.read<StudentsBloc>().add(SearchStudentsEvent(value));
    });
    setState(() {}); // لتحديث زر المسح فقط
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<StudentsBloc>().add(const FetchStudents());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('students.searchHint'),
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: context.tr('common.clear'),
                onPressed: _clear,
              ),
      ),
    );
  }
}

/// 📁 جسم الصفحة: قائمة / فراغ / خطأ / تحميل
class _StudentsBody extends StatelessWidget {
  const _StudentsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentsBloc, StudentsState>(
      // ✅ لا يُعاد البناء إلا عند تغيّر حالة الطلاب فعلًا
      buildWhen: (StudentsState previous, StudentsState current) =>
          previous.studentsState != current.studentsState,
      builder: (BuildContext context, StudentsState state) {
        return switch (state.studentsState) {
          Initial() => const SizedBox.shrink(),
          Loading() => const Center(child: CircularProgressIndicator()),
          Empty() => const _EmptyStudents(),
          Error(message: final String message) => _ErrorStudents(
              message: message,
              onRetry: () =>
                  context.read<StudentsBloc>().add(const FetchStudents()),
            ),
          Success(data: final List<StudentEntity> students) =>
            _StudentsList(students: students),
        };
      },
    );
  }
}

/// 📁 زر إضافة طالب
class _AddStudentButton extends StatelessWidget {
  const _AddStudentButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'add_student_fab',
      tooltip: context.tr('students.add'),
      onPressed: () => _openAddStudent(context),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _openAddStudent(BuildContext context) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddStudentPage()),
    );
    if (result == true && context.mounted) {
      context.read<StudentsBloc>().add(const FetchStudents());
    }
  }
}

/// 📁 قائمة الطلاب
class _StudentsList extends StatelessWidget {
  const _StudentsList({required this.students});

  final List<StudentEntity> students;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 80.h),
      itemCount: students.length,
      itemBuilder: (BuildContext context, int index) {
        return _StudentCard(student: students[index]);
      },
    );
  }
}

/// 📁 بطاقة طالب
class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 6.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Radius.item),
      ),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: colors.primaryContainer,
          child: Text(
            _initial(student),
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
        // ✅ نص مُترجم بدل 'الرقم: ...' المكتوب مباشرة في الكود
        subtitle: Text(
          '${context.tr('students.studentCode')}: ${student.studentCode}',
          style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 18.sp,
                color: colors.primary,
              ),
              tooltip: context.tr('common.edit'),
              onPressed: () => _openEdit(context),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18.sp,
                color: colors.error,
              ),
              tooltip: context.tr('common.delete'),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        onTap: () => _openDetails(context),
      ),
    );
  }

  /// الحرف الأول من الاسم — للعرض في الدائرة
  static String _initial(StudentEntity student) {
    final String name = student.firstName.trim();
    return name.isEmpty ? '؟' : name.substring(0, 1);
  }

  Future<void> _openEdit(BuildContext context) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditStudentPage(student: student),
      ),
    );
    if (result == true && context.mounted) {
      context.read<StudentsBloc>().add(const FetchStudents());
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StudentDetailsPage(student: student),
      ),
    );
    if (result == true && context.mounted) {
      context.read<StudentsBloc>().add(const FetchStudents());
    }
  }

  /// حوار تأكيد الحذف
  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Text(dialogContext.tr('dialogs.confirmDelete')),
          content: Text(
            '${dialogContext.tr('students.deleteConfirm')} '
            '${student.fullName}؟',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.tr('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text(dialogContext.tr('common.delete')),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final int? id = student.id;
      if (id != null) {
        context.read<StudentsBloc>().add(DeleteStudentEvent(id));
      }
    }
  }
}

/// 📁 حالة فارغة
class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
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
            context.tr('students.empty'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: _Gap.xs),
          Text(
            context.tr('students.emptyHint'),
            style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 📁 حالة خطأ
class _ErrorStudents extends StatelessWidget {
  const _ErrorStudents({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
              label: Text(context.tr('common.retry')),
              style: ElevatedButton.styleFrom(minimumSize: Size(150.w, 40.h)),
            ),
          ],
        ),
      ),
    );
  }
}

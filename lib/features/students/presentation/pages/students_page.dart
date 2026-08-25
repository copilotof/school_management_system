import 'package:flutter/material.dart';
import 'package:school_management_system/features/students/data/models/student_mapper.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 صفحة إدارة الطلاب - نسخة بسيطة للاختبار

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late final StudentLocalDataSource _dataSource;
  List<StudentEntity> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dataSource = getIt<StudentLocalDataSource>();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _dataSource.getAllStudents();
      setState(() {
        _students = rows.map((r) => r.toEntity()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestStudent() async {
    final student = StudentEntity(
      studentCode: 'STU${DateTime.now().millisecondsSinceEpoch}',
      firstName: 'أحمد',
      lastName: 'محمد',
      dateOfBirth: DateTime(2010, 5, 15),
      gender: 'male',
      address: 'الجزائر',
      phone: '0550000000',
    );

    try {
      final companion = StudentMapper.fromEntity(student);
      await _dataSource.createStudent(companion);
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة الطالب بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      await _dataSource.deleteStudent(id);
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الطالب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Theme.of(context) بدلاً من AppColors
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colors.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onBackground),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStudents,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : _students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد طلاب مسجلون',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على + لإضافة طالب',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
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
                    title: Text(
                      student.fullName,
                      style: TextStyle(color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'الرقم: ${student.studentCode}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.error),
                      onPressed: () => _deleteStudent(student.id!),
                    ),
                    onTap: () {
                      // سنضيف صفحة التفاصيل لاحقاً
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

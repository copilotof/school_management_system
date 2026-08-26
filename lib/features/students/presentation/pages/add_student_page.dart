import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/students/presentation/widgets/student_form.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 صفحة إضافة طالب جديد - النسخة الكاملة

class AddStudentPage extends StatelessWidget {
  const AddStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentsBloc>(),
      child: const AddStudentView(),
    );
  }
}

class AddStudentView extends StatefulWidget {
  const AddStudentView({super.key});

  @override
  State<AddStudentView> createState() => _AddStudentViewState();
}

class _AddStudentViewState extends State<AddStudentView> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة طالب جديد')),
      body: SafeArea(
        child: BlocListener<StudentsBloc, StudentsState>(
          listener: (context, state) {
            // ✅ الاستماع للنجاح
            if (state.studentsState is Success && _isSubmitting) {
              _isSubmitting = false;
              // العودة للصفحة السابقة مع رسالة نجاح
              Navigator.of(context).pop(true);
            }

            // ✅ الاستماع للخطأ
            if (state.errorMessage != null) {
              _isSubmitting = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: colors.error,
                ),
              );
            }
          },
          child: BlocBuilder<StudentsBloc, StudentsState>(
            buildWhen: (previous, current) =>
                previous.studentsState != current.studentsState,
            builder: (context, state) {
              return StudentForm(
                isLoading: _isSubmitting,
                onSubmit: (student) {
                  setState(() => _isSubmitting = true);
                  context.read<StudentsBloc>().add(CreateStudentEvent(student));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

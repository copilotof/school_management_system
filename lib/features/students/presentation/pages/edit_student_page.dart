import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/students/presentation/widgets/student_form.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 صفحة تعديل طالب

class EditStudentPage extends StatelessWidget {
  final StudentEntity student;

  const EditStudentPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentsBloc>(),
      child: EditStudentView(student: student),
    );
  }
}

class EditStudentView extends StatefulWidget {
  final StudentEntity student;
  const EditStudentView({super.key, required this.student});

  @override
  State<EditStudentView> createState() => _EditStudentViewState();
}

class _EditStudentViewState extends State<EditStudentView> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات الطالب')),
      body: SafeArea(
        child: BlocListener<StudentsBloc, StudentsState>(
          listener: (context, state) {
            if (state.studentsState is Success && _isSubmitting) {
              _isSubmitting = false;
              Navigator.of(context).pop(true);
            }

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
                initialStudent: widget.student,
                isLoading: _isSubmitting,
                onSubmit: (updatedStudent) {
                  setState(() => _isSubmitting = true);
                  context.read<StudentsBloc>().add(
                    UpdateStudentEvent(updatedStudent),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

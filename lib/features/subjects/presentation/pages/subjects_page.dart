import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_state.dart';
import 'package:school_management_system/injection_container.dart';

import '../../../../core/utils/translation_extension.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SubjectsBloc>()..add(const FetchSubjects()),
      child: const SubjectsView(),
    );
  }
}

class SubjectsView extends StatelessWidget {
  const SubjectsView({super.key});

  void _showAddDialog(BuildContext context, {SubjectEntity? subject}) {
    showDialog(
      context: context,
      builder: (_) => _AddSubjectDialog(
        subject: subject,
        subjectsBloc: context.read<SubjectsBloc>(),
      ),
    );
  }

  Future<void> _deleteSubject(
    BuildContext context,
    SubjectEntity subject,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: context.tr('dialogs.confirmDelete'),
      message: context.tr(
        'subjects.deleteMessage',
        params: {'name': subject.name},
      ),
    );
    if (confirmed && context.mounted) {
      context.read<SubjectsBloc>().add(DeleteSubjectEvent(subject.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subjects.title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (query) {
                context.read<SubjectsBloc>().add(SearchSubjectsEvent(query));
              },
              decoration: InputDecoration(
                hintText: context.tr('subjects.searchHint'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SubjectsBloc, SubjectsState>(
              buildWhen: (prev, current) =>
                  prev.subjectsState != current.subjectsState,
              builder: (context, state) {
                return switch (state.subjectsState) {
                  Initial() => const SizedBox.shrink(),
                  Loading() => const Center(child: CircularProgressIndicator()),
                  Empty() => Center(child: Text(context.tr('subjects.empty'))),
                  Error(message: final msg) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(msg),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SubjectsBloc>().add(
                              const FetchSubjects(),
                            );
                          },
                          child: Text(context.tr('common.retry')),
                        ),
                      ],
                    ),
                  ),
                  Success(data: final subjects) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.book_outlined,
                              color: colors.primary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(subject.name),
                          subtitle: subject.code != null
                              ? Text(
                                  '${context.tr('subjects.code')}: ${subject.code}',
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colors.primary,
                                ),
                                tooltip: context.tr('common.edit'),
                                onPressed: () =>
                                    _showAddDialog(context, subject: subject),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                tooltip: context.tr('common.delete'),
                                onPressed: () =>
                                    _deleteSubject(context, subject),
                              ),
                            ],
                          ),
                        ),
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
        heroTag: 'add_subject_fab',
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddSubjectDialog extends StatefulWidget {
  final SubjectEntity? subject;
  final SubjectsBloc subjectsBloc;

  const _AddSubjectDialog({this.subject, required this.subjectsBloc});

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _codeController = TextEditingController(text: widget.subject?.code ?? '');
    _descriptionController = TextEditingController(
      text: widget.subject?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            '${context.tr('subjects.name')}: ${context.tr('validators.required')}',
      );
      return;
    }

    final entity = SubjectEntity(
      id: widget.subject?.id,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: widget.subject?.isActive ?? true,
    );

    if (widget.subject == null) {
      widget.subjectsBloc.add(CreateSubjectEvent(entity));
    } else {
      widget.subjectsBloc.add(UpdateSubjectEvent(entity));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.subject == null
            ? context.tr('subjects.add')
            : context.tr('subjects.edit'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${context.tr('subjects.name')} *',
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: context.tr('subjects.code'),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: context.tr('subjects.description'),
              ),
              maxLines: 2,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: colors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18.sp, color: colors.error),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12.sp, color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(
            widget.subject == null
                ? context.tr('subjects.add')
                : context.tr('common.save'),
          ),
        ),
      ],
    );
  }
}

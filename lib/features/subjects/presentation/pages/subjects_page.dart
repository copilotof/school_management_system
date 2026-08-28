import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_state.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 صفحة إدارة المواد الدراسية

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
    // ✅ إنشاء controllers
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final descriptionController = TextEditingController(
      text: subject?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(subject == null ? 'إضافة مادة' : 'تعديل مادة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المادة *'),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'الرمز (اختياري)',
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                final entity = SubjectEntity(
                  id: subject?.id,
                  name: nameController.text.trim(),
                  code: codeController.text.trim().isEmpty
                      ? null
                      : codeController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  isActive: subject?.isActive ?? true,
                );

                if (subject == null) {
                  context.read<SubjectsBloc>().add(CreateSubjectEvent(entity));
                } else {
                  context.read<SubjectsBloc>().add(UpdateSubjectEvent(entity));
                }

                Navigator.of(dialogContext).pop();
                // ✅ لا تستدعي dispose() هنا
              },
              child: Text(subject == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (query) {
                context.read<SubjectsBloc>().add(SearchSubjectsEvent(query));
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن مادة...',
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
                  Empty() => const Center(child: Text('لا توجد مواد')),
                  Error(message: final msg) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(msg),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SubjectsBloc>().add(
                              const FetchSubjects(),
                            );
                          },
                          child: const Text('إعادة المحاولة'),
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
                              ? Text('الرمز: ${subject.code}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colors.primary,
                                ),
                                onPressed: () =>
                                    _showAddDialog(context, subject: subject),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                onPressed: () {
                                  context.read<SubjectsBloc>().add(
                                    DeleteSubjectEvent(subject.id!),
                                  );
                                },
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
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

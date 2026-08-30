import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/levels/domain/entities/level_entity.dart';
import 'package:school_management_system/features/levels/presentation/bloc/levels_bloc.dart';
import 'package:school_management_system/injection_container.dart';

class LevelsPage extends StatelessWidget {
  const LevelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LevelsBloc>()..add(FetchLevels()),
      child: const LevelsView(),
    );
  }
}

class LevelsView extends StatelessWidget {
  const LevelsView({super.key});

  void _showAddDialog(BuildContext context, {LevelEntity? level}) {
    final levelsBloc = context.read<LevelsBloc>();
    final nameController = TextEditingController(text: level?.name ?? '');
    final orderController = TextEditingController(
      text: level?.orderIndex.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(level == null ? 'إضافة مستوى' : 'تعديل مستوى'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المستوى *'),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الترتيب'),
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
                final entity = LevelEntity(
                  id: level?.id,
                  name: nameController.text.trim(),
                  orderIndex: int.tryParse(orderController.text) ?? 0,
                  isActive: level?.isActive ?? true,
                );
                if (level == null) {
                  levelsBloc.add(CreateLevelEvent(entity));
                } else {
                  levelsBloc.add(UpdateLevelEvent(entity));
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(level == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLevel(BuildContext context, LevelEntity level) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف المستوى "${level.name}"؟',
    );
    if (confirmed && context.mounted) {
      context.read<LevelsBloc>().add(DeleteLevelEvent(level.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستويات الدراسية'),
        // ✅ بدون automaticallyImplyLeading: false
      ),
      body: BlocBuilder<LevelsBloc, LevelsState>(
        builder: (context, state) {
          return switch (state.levelsState) {
            Initial() => const SizedBox.shrink(),
            Loading() => const Center(child: CircularProgressIndicator()),
            Empty() => const Center(child: Text('لا توجد مستويات')),
            Error(message: final msg) => Center(child: Text(msg)),
            Success(data: final levels) => ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.school_outlined,
                        color: colors.primary,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(level.name),
                    subtitle: Text('الترتيب: ${level.orderIndex}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colors.primary,
                          ),
                          onPressed: () =>
                              _showAddDialog(context, level: level),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed: () => _deleteLevel(context, level),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_level_fab',
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:io';

import 'package:school_management_system/core/services/backup_service.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/injection_container.dart';

class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة النسخ الاحتياطي والاستعادة
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupService _backupService;

  DatabaseInfo? _dbInfo;
  List<BackupInfo> _backups = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _backupService = getIt<BackupService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final dbInfo = await _backupService.getDatabaseInfo();
    final backups = await _backupService.getBackupsList();

    if (!mounted) return;

    setState(() {
      _dbInfo = dbInfo;
      _backups = backups;
      _isLoading = false;
    });
  }

  /// ✅ إنشاء نسخة احتياطية
  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);

    final result = await _backupService.createBackup(label: 'manual');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (result.success && result.backupPath != null) {
      // ✅ جلب معلومات النسخة
      final file = File(result.backupPath!);
      final stat = await file.stat();

      // ✅ عدد النسخ الحالية
      final backupsCount = _backups.length + 1;

      if (!mounted) return;

      // ✅ حوار تأكيد النجاح
      await _showBackupSuccessDialog(
        sizeInBytes: stat.size,
        createdAt: stat.modified,
        backupsCount: backupsCount,
      );

      await _loadData();
    } else {
      _showSnack(
        'فشل: ${result.error}',
        color: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// ✅ حوار نجاح إنشاء النسخة
  Future<void> _showBackupSuccessDialog({
    required int sizeInBytes,
    required DateTime createdAt,
    required int backupsCount,
  }) async {
    final colors = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: colors.secondaryContainer,
              child: Icon(
                Icons.check_circle,
                color: colors.onSecondaryContainer,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'تم إنشاء النسخة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تم إنشاء نسخة احتياطية بنجاح.',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            // تفاصيل النسخة
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  _successRow(
                    icon: Icons.calendar_today,
                    label: 'التاريخ',
                    value: DateFormat('yyyy/MM/dd').format(createdAt),
                    colors: colors,
                  ),
                  Divider(height: 12.h, color: colors.outlineVariant),
                  _successRow(
                    icon: Icons.access_time,
                    label: 'الوقت',
                    value: DateFormat('HH:mm:ss').format(createdAt),
                    colors: colors,
                  ),
                  Divider(height: 12.h, color: colors.outlineVariant),
                  _successRow(
                    icon: Icons.storage,
                    label: 'الحجم',
                    value: _formatBytes(sizeInBytes),
                    colors: colors,
                  ),
                  Divider(height: 12.h, color: colors.outlineVariant),
                  _successRow(
                    icon: Icons.folder_special,
                    label: 'إجمالي النسخ',
                    value: '$backupsCount نسخة',
                    colors: colors,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: colors.tertiary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: colors.tertiary),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'يمكنك الآن مشاركة النسخة أو استعادتها في أي وقت.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('حسناً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: colors.onSecondary,
              minimumSize: Size(0, 42.h),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ صف تفصيلي في حوار النجاح
  Widget _successRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colors,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: colors.primary),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  /// ✅ تنسيق الحجم
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// ✅ استعادة نسخة
  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الاستعادة',
      message:
          'هل أنت متأكد من استعادة النسخة الاحتياطية؟\n\n'
          'سيتم استبدال البيانات الحالية بالكامل.\n'
          'سيتم إنشاء نسخة أمان تلقائياً.',
      confirmText: 'استعادة',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    final result = await _backupService.restoreBackup(backup.path);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (result.success) {
      // حوار نجاح
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8.w),
              const Text('تمت الاستعادة'),
            ],
          ),
          content: Text(
            // 'تمت استعادة النسخة بنجاح.\n\n'
            context.tr('prompts.restartToApply'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } else {
      _showSnack(
        'فشل: ${result.error}',
        color: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// ✅ حذف نسخة
  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف هذه النسخة؟',
    );

    if (!confirmed) return;

    final success = await _backupService.deleteBackup(backup.path);

    if (!mounted) return;

    if (success) {
      _showSnack('تم الحذف', color: Theme.of(context).colorScheme.secondary);
      await _loadData();
    } else {
      _showSnack('فشل الحذف', color: Theme.of(context).colorScheme.error);
    }
  }

  /// ✅ مشاركة نسخة
  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      await _backupService.shareBackup(backup.path);
    } catch (e) {
      if (mounted) {
        _showSnack(
          'فشل المشاركة: $e',
          color: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  /// ✅ حذف النسخ القديمة
  Future<void> _deleteOldBackups() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'حذف النسخ القديمة',
      message: 'سيتم حذف النسخ الأقدم من 30 يوماً.',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    final count = await _backupService.deleteOldBackups(daysOld: 30);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    _showSnack(
      'تم حذف $count نسخة قديمة',
      color: Theme.of(context).colorScheme.secondary,
    );
    await _loadData();
  }

  void _showSnack(String message, {required Color color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ====== بطاقة قاعدة البيانات ======
                        if (_dbInfo != null) _buildDbInfoCard(colors),
                        SizedBox(height: _Gap.md),

                        // ====== أزرار الإجراءات ======
                        _buildActionsCard(colors),
                        SizedBox(height: _Gap.md),

                        // ====== قائمة النسخ ======
                        _buildBackupsList(colors),
                      ],
                    ),
                  ),
                ),

                // ====== شريط سفلي ======
                _buildBottomBar(colors),
              ],
            ),
    );
  }

  Widget _buildDbInfoCard(ColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: Colors.white, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'قاعدة البيانات الحالية',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _dbInfoRow('الحجم', _dbInfo!.sizeFormatted),
          SizedBox(height: 4.h),
          _dbInfoRow(
            'آخر تعديل',
            DateFormat('yyyy/MM/dd HH:mm').format(_dbInfo!.modifiedAt),
          ),
        ],
      ),
    );
  }

  Widget _dbInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(ColorScheme colors) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.backup,
                color: colors.onSecondaryContainer,
                size: 20.sp,
              ),
            ),
            title: const Text('إنشاء نسخة احتياطية'),
            subtitle: const Text('نسخ قاعدة البيانات الحالية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isProcessing ? null : _createBackup,
          ),
          Divider(height: 1, color: colors.surfaceVariant),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.delete_sweep,
                color: colors.onTertiaryContainer,
                size: 20.sp,
              ),
            ),
            title: const Text('حذف النسخ القديمة'),
            subtitle: const Text('أقدم من 30 يوماً'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isProcessing ? null : _deleteOldBackups,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList(ColorScheme colors) {
    if (_backups.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48.sp,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 8.h),
            Text(
              'لا توجد نسخ احتياطية',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: 4.h),
            Text(
              'اضغط "إنشاء نسخة احتياطية" للبدء',
              style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16.sp, color: colors.primary),
            SizedBox(width: 6.w),
            Text(
              'النسخ المتوفرة (${_backups.length})',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ..._backups.map(
          (backup) => _BackupCard(
            backup: backup,
            onRestore: () => _restoreBackup(backup),
            onDelete: () => _deleteBackup(backup),
            onShare: () => _shareBackup(backup),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _createBackup,
            icon: _isProcessing
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.backup, size: 18),
            label: const Text('إنشاء نسخة احتياطية'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 📁 بطاقة نسخة احتياطية
class _BackupCard extends StatelessWidget {
  final BackupInfo backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.description,
                    size: 18.sp,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(backup.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        backup.sizeFormatted,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore, size: 14),
                    label: const Text(
                      'استعادة',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 14),
                    label: const Text('مشاركة', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                SizedBox(
                  width: 40.w,
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error),
                    ),
                    child: Icon(Icons.delete_outline, size: 16.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

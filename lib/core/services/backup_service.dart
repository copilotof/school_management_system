import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 📁 خدمة النسخ الاحتياطي والاستعادة
class BackupService {
  static const String _dbFileName = 'school_management_db.sqlite';
  static const String _backupFolderName = 'school_management_backups';

  /// ✅ المسار الكامل لملف قاعدة البيانات
  Future<String> _getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  /// ✅ مجلد النسخ الاحتياطية
  Future<Directory> _getBackupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, _backupFolderName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// ✅ التحقق من وجود قاعدة البيانات
  Future<bool> databaseExists() async {
    final dbPath = await _getDbPath();
    return File(dbPath).exists();
  }

  /// ✅ الحصول على معلومات قاعدة البيانات
  Future<DatabaseInfo?> getDatabaseInfo() async {
    try {
      final dbPath = await _getDbPath();
      final file = File(dbPath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      return DatabaseInfo(
        path: dbPath,
        sizeInBytes: stat.size,
        modifiedAt: stat.modified,
      );
    } catch (e) {
      debugPrint('🔴 خطأ في جلب معلومات قاعدة البيانات: $e');
      return null;
    }
  }

  /// ✅ إنشاء نسخة احتياطية
  Future<BackupResult> createBackup({String? label}) async {
    try {
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return BackupResult(success: false, error: 'قاعدة البيانات غير موجودة');
      }

      final backupDir = await _getBackupDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final labelPart = label != null && label.isNotEmpty ? '_$label' : '';
      final backupFileName = 'backup_$timestamp$labelPart.sqlite';
      final backupPath = p.join(backupDir.path, backupFileName);

      // نسخ الملف
      await dbFile.copy(backupPath);

      final stat = await File(backupPath).stat();

      debugPrint('✅ تم إنشاء نسخة احتياطية: $backupPath');

      return BackupResult(
        success: true,
        backupPath: backupPath,
        sizeInBytes: stat.size,
      );
    } catch (e) {
      debugPrint('🔴 خطأ في النسخ الاحتياطي: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  /// ✅ قائمة النسخ الاحتياطية
  Future<List<BackupInfo>> getBackupsList() async {
    try {
      final backupDir = await _getBackupDir();
      final files = await backupDir.list().toList();

      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.sqlite')) {
          final stat = await file.stat();
          backups.add(
            BackupInfo(
              path: file.path,
              fileName: p.basename(file.path),
              sizeInBytes: stat.size,
              createdAt: stat.modified,
            ),
          );
        }
      }

      // ترتيب تنازلي حسب التاريخ
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      debugPrint('🔴 خطأ في جلب النسخ: $e');
      return [];
    }
  }

  /// ✅ استعادة نسخة احتياطية
  Future<BackupResult> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return BackupResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير موجود',
        );
      }

      final dbPath = await _getDbPath();

      // نسخ النسخة الحالية كأمان
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final safetyPath = '$dbPath.before_restore';
        await dbFile.copy(safetyPath);
      }

      // استبدال الملف
      await backupFile.copy(dbPath);

      debugPrint('✅ تم استعادة النسخة الاحتياطية');

      return BackupResult(success: true, backupPath: dbPath);
    } catch (e) {
      debugPrint('🔴 خطأ في الاستعادة: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  /// ✅ حذف نسخة احتياطية
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🔴 خطأ في الحذف: $e');
      return false;
    }
  }

  /// ✅ مشاركة نسخة احتياطية
  Future<void> shareBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'نسخة احتياطية - نظام إدارة المدارس',
        text: 'نسخة احتياطية بتاريخ ${DateTime.now()}',
      );
    } catch (e) {
      debugPrint('🔴 خطأ في المشاركة: $e');
      rethrow;
    }
  }

  /// ✅ حذف النسخ القديمة (أقدم من X يوم)
  Future<int> deleteOldBackups({int daysOld = 30}) async {
    try {
      final backups = await getBackupsList();
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      int deleted = 0;

      for (final backup in backups) {
        if (backup.createdAt.isBefore(cutoff)) {
          if (await deleteBackup(backup.path)) {
            deleted++;
          }
        }
      }

      return deleted;
    } catch (e) {
      debugPrint('🔴 خطأ في حذف النسخ القديمة: $e');
      return 0;
    }
  }

  /// ✅ الحصول على مسار مجلد النسخ الاحتياطية
  Future<String> getBackupDirectoryPath() async {
    final dir = await _getBackupDir();
    return dir.path;
  }
}

/// 📁 معلومات قاعدة البيانات
class DatabaseInfo {
  final String path;
  final int sizeInBytes;
  final DateTime modifiedAt;

  const DatabaseInfo({
    required this.path,
    required this.sizeInBytes,
    required this.modifiedAt,
  });

  String get sizeFormatted => _formatBytes(sizeInBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 📁 معلومات نسخة احتياطية
class BackupInfo {
  final String path;
  final String fileName;
  final int sizeInBytes;
  final DateTime createdAt;

  const BackupInfo({
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
    required this.createdAt,
  });

  String get sizeFormatted => DatabaseInfo._formatBytes(sizeInBytes);
}

/// 📁 نتيجة عملية النسخ/الاستعادة
class BackupResult {
  final bool success;
  final String? backupPath;
  final int? sizeInBytes;
  final String? error;

  const BackupResult({
    required this.success,
    this.backupPath,
    this.sizeInBytes,
    this.error,
  });
}

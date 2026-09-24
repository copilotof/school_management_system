import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الإعدادات
class SettingsLocalDataSource {
  final AppDatabase db;

  SettingsLocalDataSource({required this.db});

  /// جلب قيمة إعداد
  Future<String?> getValue(String key) async {
    final setting = await (db.select(
      db.systemSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  /// ✅ حفظ قيمة إعداد (مع التحقق من الوجود)
  Future<void> setValue(String key, String value) async {
    // 1. جلب الإعداد إذا كان موجوداً
    final existing = await (db.select(
      db.systemSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();

    if (existing != null) {
      // 2. تحديث
      await (db.update(
        db.systemSettings,
      )..where((t) => t.key.equals(key))).write(
        SystemSettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // 3. إدراج جديد
      await db
          .into(db.systemSettings)
          .insert(
            SystemSettingsCompanion.insert(
              key: key,
              value: value,
              updatedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  /// جلب عدد الغيابات المسموح
  Future<int> getAbsenceLimit() async {
    final value = await getValue('absence_limit');
    return int.tryParse(value ?? '5') ?? 5;
  }

  /// حفظ عدد الغيابات المسموح
  Future<void> setAbsenceLimit(int limit) async {
    await setValue('absence_limit', limit.toString());
  }
}

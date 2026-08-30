import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

class LevelLocalDataSource {
  final AppDatabase db;

  LevelLocalDataSource({required this.db});

  Future<List<AcademicLevel>> getAllLevels() async {
    return await (db.select(
      db.academicLevels,
    )..orderBy([(t) => OrderingTerm(expression: t.orderIndex)])).get();
  }

  Future<int> createLevel(AcademicLevelsCompanion level) async {
    return await db.into(db.academicLevels).insert(level);
  }

  Future<bool> updateLevel(AcademicLevel level) async {
    return await db.update(db.academicLevels).replace(level);
  }

  Future<int> deleteLevel(int id) async {
    return await (db.delete(
      db.academicLevels,
    )..where((t) => t.id.equals(id))).go();
  }
}

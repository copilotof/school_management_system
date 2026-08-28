import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات المواد المحلي

class SubjectLocalDataSource {
  final AppDatabase db;

  SubjectLocalDataSource({required this.db});

  Future<List<Subject>> getAllSubjects() async {
    return await (db.select(
      db.subjects,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Stream<List<Subject>> watchAllSubjects() {
    return (db.select(
      db.subjects,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<Subject?> getSubjectById(int id) async {
    return await (db.select(
      db.subjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Subject>> searchSubjects(String query) async {
    final term = '%$query%';
    return await (db.select(
      db.subjects,
    )..where((t) => t.name.like(term) | t.code.like(term))).get();
  }

  Future<int> createSubject(SubjectsCompanion subject) async {
    return await db.into(db.subjects).insert(subject);
  }

  Future<bool> updateSubject(Subject subject) async {
    return await db.update(db.subjects).replace(subject);
  }

  Future<int> deleteSubject(int id) async {
    return await (db.delete(db.subjects)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getSubjectsCount() async {
    final all = await getAllSubjects();
    return all.length;
  }
}

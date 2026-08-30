import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الأفواج المحلي

class GroupLocalDataSource {
  final AppDatabase db;

  GroupLocalDataSource({required this.db});

  Future<List<Group>> getAllGroups() async {
    return await (db.select(
      db.groups,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Group?> getGroupById(int id) async {
    return await (db.select(
      db.groups,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Group>> searchGroups(String query) async {
    final term = '%$query%';
    return await (db.select(db.groups)..where((t) => t.name.like(term))).get();
  }

  Future<int> createGroup(GroupsCompanion group) async {
    return await db.into(db.groups).insert(group);
  }

  Future<bool> updateGroup(Group group) async {
    return await db.update(db.groups).replace(group);
  }

  Future<int> deleteGroup(int id) async {
    return await (db.delete(db.groups)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getGroupsCount() async {
    final all = await getAllGroups();
    return all.length;
  }
}

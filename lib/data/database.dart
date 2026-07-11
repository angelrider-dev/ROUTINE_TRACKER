import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, TaskCompletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this and add a MigrationStrategy when the schema changes later.
  @override
  int get schemaVersion => 1;

  // ---- Tasks -------------------------------------------------------

  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  Future<void> insertTask(TasksCompanion task) =>
      into(tasks).insertOnConflictUpdate(task);

  Future<void> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // ---- Completions ---------------------------------------------------

  /// All completions, watched live. The provider layer derives
  /// per-day / per-task lookups and streaks from this in memory —
  /// cheap enough for a personal routine tracker's data volume.
  Stream<List<TaskCompletion>> watchAllCompletions() =>
      select(taskCompletions).watch();

  Future<void> setCompletion(String taskId, DateTime date, bool done) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final existing = await (select(taskCompletions)
          ..where((c) => c.taskId.equals(taskId) & c.date.equals(normalized)))
        .getSingleOrNull();

    if (existing == null) {
      await into(taskCompletions).insert(
        TaskCompletionsCompanion.insert(
          taskId: taskId,
          date: normalized,
          done: Value(done),
        ),
      );
    } else {
      await (update(taskCompletions)..where((c) => c.id.equals(existing.id)))
          .write(TaskCompletionsCompanion(done: Value(done)));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'routine_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

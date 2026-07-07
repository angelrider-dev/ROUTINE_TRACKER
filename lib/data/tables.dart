import 'package:drift/drift.dart';

/// One row per task the user has created (habit or plain task).
/// Category and recurrence are stored as text (enum names) so the schema
/// stays readable in a DB browser and survives enum-reordering safely.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => text()(); // TaskCategory.name
  TextColumn get recurrence => text().withDefault(const Constant('daily'))();
  TextColumn get customDays => text().nullable()(); // comma-separated ints
  IntColumn get scheduledHour => integer().nullable()();
  IntColumn get scheduledMinute => integer().nullable()();
  BoolColumn get isHabit => boolean().withDefault(const Constant(false))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per (task, date) completion record. `date` is always
/// normalized to midnight so lookups by day are exact matches.
class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get done => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, date}
      ];
}

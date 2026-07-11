import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

/// Single shared database instance for the app's lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ---- Mapping between Drift rows and the app-level RoutineTask model ----

RoutineTask _taskFromRow(Task row) {
  return RoutineTask(
    id: row.id,
    title: row.title,
    category: TaskCategory.values.byName(row.category),
    createdAt: row.createdAt,
    recurrence: RecurrenceType.values.byName(row.recurrence),
    customDays: (row.customDays == null || row.customDays!.isEmpty)
        ? null
        : row.customDays!.split(',').map(int.parse).toList(),
    scheduledTime: row.scheduledHour == null
        ? null
        : TimeOfDay(hour: row.scheduledHour!, minute: row.scheduledMinute ?? 0),
    isHabit: row.isHabit,
    reminderEnabled: row.reminderEnabled,
  );
}

TasksCompanion _taskToCompanion(RoutineTask t) {
  return TasksCompanion.insert(
    id: t.id,
    title: t.title,
    category: t.category.name,
    recurrence: Value(t.recurrence.name),
    customDays: Value(t.customDays?.join(',')),
    scheduledHour: Value(t.scheduledTime?.hour),
    scheduledMinute: Value(t.scheduledTime?.minute),
    isHabit: Value(t.isHabit),
    reminderEnabled: Value(t.reminderEnabled),
  );
}

/// Live list of all tasks, streamed from the database.
final tasksProvider = StreamProvider<List<RoutineTask>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTasks().map((rows) => rows.map(_taskFromRow).toList());
});

/// Live map of all completions, keyed "taskId|yyyy-mm-dd" -> done.
/// Kept as a flat map in memory (cheap at personal-tracker data volumes)
/// so the UI layer can do cheap lookups without re-querying per tile.
final completionsProvider = StreamProvider<Map<String, bool>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCompletions().map((rows) {
    final map = <String, bool>{};
    for (final row in rows) {
      final d = row.date;
      map['${row.taskId}|${d.year}-${d.month}-${d.day}'] = row.done;
    }
    return map;
  });
});

/// Actions that mutate tasks/completions. Kept separate from the streamed
/// state above — call methods here, read state via the providers above.
final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(databaseProvider), ref.watch(notificationServiceProvider));
});

class TaskActions {
  final AppDatabase _db;
  final NotificationService _notifications;
  TaskActions(this._db, this._notifications);

  /// Returns true if the reminder (if any) was scheduled successfully.
  /// False means the task itself still saved fine, but no reminder was
  /// set — e.g. notification permission is missing, or (for a one-off
  /// task) its scheduled time has already passed. Callers can show a
  /// warning to the user instead of assuming reminders always work.
  Future<bool> addTask(RoutineTask task) async {
    await _db.insertTask(_taskToCompanion(task));
    return _notifications.rescheduleFor(task);
  }

  Future<bool> updateTask(RoutineTask task) async {
    await _db.insertTask(_taskToCompanion(task));
    return _notifications.rescheduleFor(task);
  }

  Future<void> removeTask(String id) async {
    await _db.deleteTask(id);
    await _notifications.cancelFor(id);
  }

  Future<void> toggle(String taskId, DateTime date, bool currentlyDone) =>
      _db.setCompletion(taskId, date, !currentlyDone);
}

// ---- Derived helpers, built on top of the streamed maps above ----

/// Single source of truth for "does this task appear on this day",
/// respecting RecurrenceType. Every screen (Today, Habits, History,
/// Stats) must filter through this — previously nothing did, so a
/// "Weekdays only" task was showing up on Saturdays.
///
/// One-off tasks are treated as appearing only on their creation date —
/// there's no separate "due date" field in the model, so this is the one
/// reasonable reading of "one-off" given what's actually stored.
bool isScheduledOn(RoutineTask task, DateTime day) {
  if (task.createdAfter(day)) return false;
  switch (task.recurrence) {
    case RecurrenceType.oneOff:
      return normalizeDate(task.createdAt) == normalizeDate(day);
    case RecurrenceType.daily:
      return true;
    case RecurrenceType.weekdays:
      return day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
    case RecurrenceType.custom:
      return (task.customDays ?? const []).contains(day.weekday);
  }
}

bool isDoneOn(Map<String, bool> completions, String taskId, DateTime date) {
  final d = normalizeDate(date);
  return completions['$taskId|${d.year}-${d.month}-${d.day}'] ?? false;
}

/// Current consecutive-completion streak, counting backward from today.
/// Days the task ISN'T scheduled on (e.g. weekends for a weekdays-only
/// habit) are skipped over rather than breaking the streak — walking
/// back stops once we reach a day before the task existed at all.
int currentStreak(List<RoutineTask> tasks, Map<String, bool> completions, String taskId) {
  RoutineTask? task;
  for (final t in tasks) {
    if (t.id == taskId) {
      task = t;
      break;
    }
  }
  if (task == null) return 0;

  int streak = 0;
  DateTime day = DateTime.now();
  final createdDay = normalizeDate(task.createdAt);

  while (!day.isBefore(createdDay)) {
    if (!isScheduledOn(task, day)) {
      day = day.subtract(const Duration(days: 1));
      continue;
    }
    if (isDoneOn(completions, taskId, day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

double todayProgress(List<RoutineTask> todaysTasks, Map<String, bool> completions) {
  if (todaysTasks.isEmpty) return 0;
  final done =
      todaysTasks.where((t) => isDoneOn(completions, t.id, DateTime.now())).length;
  return done / todaysTasks.length;
}

/// Completion percentage (0-100) for an arbitrary day, across tasks that
/// were actually scheduled on that day (respecting recurrence — not just
/// "existed by then"). Used by the Stats bar chart and History heatmap.
int completionPercentForDay(
  List<RoutineTask> tasks,
  Map<String, bool> completions,
  DateTime day,
) {
  final eligible = tasks.where((t) => isScheduledOn(t, day)).toList();
  if (eligible.isEmpty) return 0;
  final done = eligible.where((t) => isDoneOn(completions, t.id, day)).length;
  return ((done / eligible.length) * 100).round();
}

import 'package:flutter/material.dart';

enum RecurrenceType { oneOff, daily, weekdays, custom }

enum TaskCategory { fitness, work, mind, learning, reflect }

class RoutineTask {
  final String id;
  final String title;
  final TaskCategory category;
  final RecurrenceType recurrence;
  final List<int>? customDays; // 1 = Mon ... 7 = Sun, used when custom
  final TimeOfDay? scheduledTime;
  final bool isHabit;
  final bool reminderEnabled;

  /// When this task was first created. Used by History/Stats to exclude
  /// days before the task existed from completion-rate calculations —
  /// required (not defaulted internally) so every call site has to make
  /// an explicit, correct choice: pass DateTime.now() for a brand-new
  /// task, or the original task's createdAt when editing.
  final DateTime createdAt;

  RoutineTask({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.recurrence = RecurrenceType.daily,
    this.customDays,
    this.scheduledTime,
    this.isHabit = false,
    this.reminderEnabled = false,
  });

  /// True if this task didn't exist yet by the end of [day].
  bool createdAfter(DateTime day) {
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return createdAt.isAfter(endOfDay);
  }

  RoutineTask copyWith({
    String? title,
    TaskCategory? category,
    RecurrenceType? recurrence,
    List<int>? customDays,
    TimeOfDay? scheduledTime,
    bool? isHabit,
    bool? reminderEnabled,
  }) {
    return RoutineTask(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isHabit: isHabit ?? this.isHabit,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  /// Plain-map serialization for data export. TimeOfDay has no built-in
  /// JSON form, so it's split into hour/minute; everything else maps
  /// directly to JSON-safe types.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'recurrence': recurrence.name,
        'customDays': customDays,
        'scheduledHour': scheduledTime?.hour,
        'scheduledMinute': scheduledTime?.minute,
        'isHabit': isHabit,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Normalizes a DateTime to midnight (y/m/d only) so completion lookups
/// by day are exact matches. NOTE: the completion record itself is
/// represented by Drift's generated `TaskCompletion` row class (see
/// data/database.dart) — no separate app-level model needed here.
DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

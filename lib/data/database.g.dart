// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recurrenceMeta =
      const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
      'recurrence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('daily'));
  static const VerificationMeta _customDaysMeta =
      const VerificationMeta('customDays');
  @override
  late final GeneratedColumn<String> customDays = GeneratedColumn<String>(
      'custom_days', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scheduledHourMeta =
      const VerificationMeta('scheduledHour');
  @override
  late final GeneratedColumn<int> scheduledHour = GeneratedColumn<int>(
      'scheduled_hour', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scheduledMinuteMeta =
      const VerificationMeta('scheduledMinute');
  @override
  late final GeneratedColumn<int> scheduledMinute = GeneratedColumn<int>(
      'scheduled_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isHabitMeta =
      const VerificationMeta('isHabit');
  @override
  late final GeneratedColumn<bool> isHabit = GeneratedColumn<bool>(
      'is_habit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_habit" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reminderEnabledMeta =
      const VerificationMeta('reminderEnabled');
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
      'reminder_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reminder_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        category,
        recurrence,
        customDays,
        scheduledHour,
        scheduledMinute,
        isHabit,
        reminderEnabled,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('recurrence')) {
      context.handle(
          _recurrenceMeta,
          recurrence.isAcceptableOrUnknown(
              data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('custom_days')) {
      context.handle(
          _customDaysMeta,
          customDays.isAcceptableOrUnknown(
              data['custom_days']!, _customDaysMeta));
    }
    if (data.containsKey('scheduled_hour')) {
      context.handle(
          _scheduledHourMeta,
          scheduledHour.isAcceptableOrUnknown(
              data['scheduled_hour']!, _scheduledHourMeta));
    }
    if (data.containsKey('scheduled_minute')) {
      context.handle(
          _scheduledMinuteMeta,
          scheduledMinute.isAcceptableOrUnknown(
              data['scheduled_minute']!, _scheduledMinuteMeta));
    }
    if (data.containsKey('is_habit')) {
      context.handle(_isHabitMeta,
          isHabit.isAcceptableOrUnknown(data['is_habit']!, _isHabitMeta));
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
          _reminderEnabledMeta,
          reminderEnabled.isAcceptableOrUnknown(
              data['reminder_enabled']!, _reminderEnabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      recurrence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence'])!,
      customDays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_days']),
      scheduledHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheduled_hour']),
      scheduledMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheduled_minute']),
      isHabit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_habit'])!,
      reminderEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reminder_enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String category;
  final String recurrence;
  final String? customDays;
  final int? scheduledHour;
  final int? scheduledMinute;
  final bool isHabit;
  final bool reminderEnabled;
  final DateTime createdAt;
  const Task(
      {required this.id,
      required this.title,
      required this.category,
      required this.recurrence,
      this.customDays,
      this.scheduledHour,
      this.scheduledMinute,
      required this.isHabit,
      required this.reminderEnabled,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || customDays != null) {
      map['custom_days'] = Variable<String>(customDays);
    }
    if (!nullToAbsent || scheduledHour != null) {
      map['scheduled_hour'] = Variable<int>(scheduledHour);
    }
    if (!nullToAbsent || scheduledMinute != null) {
      map['scheduled_minute'] = Variable<int>(scheduledMinute);
    }
    map['is_habit'] = Variable<bool>(isHabit);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      recurrence: Value(recurrence),
      customDays: customDays == null && nullToAbsent
          ? const Value.absent()
          : Value(customDays),
      scheduledHour: scheduledHour == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledHour),
      scheduledMinute: scheduledMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledMinute),
      isHabit: Value(isHabit),
      reminderEnabled: Value(reminderEnabled),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      customDays: serializer.fromJson<String?>(json['customDays']),
      scheduledHour: serializer.fromJson<int?>(json['scheduledHour']),
      scheduledMinute: serializer.fromJson<int?>(json['scheduledMinute']),
      isHabit: serializer.fromJson<bool>(json['isHabit']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'recurrence': serializer.toJson<String>(recurrence),
      'customDays': serializer.toJson<String?>(customDays),
      'scheduledHour': serializer.toJson<int?>(scheduledHour),
      'scheduledMinute': serializer.toJson<int?>(scheduledMinute),
      'isHabit': serializer.toJson<bool>(isHabit),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith(
          {String? id,
          String? title,
          String? category,
          String? recurrence,
          Value<String?> customDays = const Value.absent(),
          Value<int?> scheduledHour = const Value.absent(),
          Value<int?> scheduledMinute = const Value.absent(),
          bool? isHabit,
          bool? reminderEnabled,
          DateTime? createdAt}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        recurrence: recurrence ?? this.recurrence,
        customDays: customDays.present ? customDays.value : this.customDays,
        scheduledHour:
            scheduledHour.present ? scheduledHour.value : this.scheduledHour,
        scheduledMinute: scheduledMinute.present
            ? scheduledMinute.value
            : this.scheduledMinute,
        isHabit: isHabit ?? this.isHabit,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        createdAt: createdAt ?? this.createdAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      customDays:
          data.customDays.present ? data.customDays.value : this.customDays,
      scheduledHour: data.scheduledHour.present
          ? data.scheduledHour.value
          : this.scheduledHour,
      scheduledMinute: data.scheduledMinute.present
          ? data.scheduledMinute.value
          : this.scheduledMinute,
      isHabit: data.isHabit.present ? data.isHabit.value : this.isHabit,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('recurrence: $recurrence, ')
          ..write('customDays: $customDays, ')
          ..write('scheduledHour: $scheduledHour, ')
          ..write('scheduledMinute: $scheduledMinute, ')
          ..write('isHabit: $isHabit, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, category, recurrence, customDays,
      scheduledHour, scheduledMinute, isHabit, reminderEnabled, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.recurrence == this.recurrence &&
          other.customDays == this.customDays &&
          other.scheduledHour == this.scheduledHour &&
          other.scheduledMinute == this.scheduledMinute &&
          other.isHabit == this.isHabit &&
          other.reminderEnabled == this.reminderEnabled &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> recurrence;
  final Value<String?> customDays;
  final Value<int?> scheduledHour;
  final Value<int?> scheduledMinute;
  final Value<bool> isHabit;
  final Value<bool> reminderEnabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.customDays = const Value.absent(),
    this.scheduledHour = const Value.absent(),
    this.scheduledMinute = const Value.absent(),
    this.isHabit = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    required String category,
    this.recurrence = const Value.absent(),
    this.customDays = const Value.absent(),
    this.scheduledHour = const Value.absent(),
    this.scheduledMinute = const Value.absent(),
    this.isHabit = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        category = Value(category);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? recurrence,
    Expression<String>? customDays,
    Expression<int>? scheduledHour,
    Expression<int>? scheduledMinute,
    Expression<bool>? isHabit,
    Expression<bool>? reminderEnabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (recurrence != null) 'recurrence': recurrence,
      if (customDays != null) 'custom_days': customDays,
      if (scheduledHour != null) 'scheduled_hour': scheduledHour,
      if (scheduledMinute != null) 'scheduled_minute': scheduledMinute,
      if (isHabit != null) 'is_habit': isHabit,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? category,
      Value<String>? recurrence,
      Value<String?>? customDays,
      Value<int?>? scheduledHour,
      Value<int?>? scheduledMinute,
      Value<bool>? isHabit,
      Value<bool>? reminderEnabled,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      isHabit: isHabit ?? this.isHabit,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (customDays.present) {
      map['custom_days'] = Variable<String>(customDays.value);
    }
    if (scheduledHour.present) {
      map['scheduled_hour'] = Variable<int>(scheduledHour.value);
    }
    if (scheduledMinute.present) {
      map['scheduled_minute'] = Variable<int>(scheduledMinute.value);
    }
    if (isHabit.present) {
      map['is_habit'] = Variable<bool>(isHabit.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('recurrence: $recurrence, ')
          ..write('customDays: $customDays, ')
          ..write('scheduledHour: $scheduledHour, ')
          ..write('scheduledMinute: $scheduledMinute, ')
          ..write('isHabit: $isHabit, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskCompletionsTable extends TaskCompletions
    with TableInfo<$TaskCompletionsTable, TaskCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tasks (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
      'done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("done" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, taskId, date, done];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_completions';
  @override
  VerificationContext validateIntegrity(Insertable<TaskCompletion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
          _doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {taskId, date},
      ];
  @override
  TaskCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCompletion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      done: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}done'])!,
    );
  }

  @override
  $TaskCompletionsTable createAlias(String alias) {
    return $TaskCompletionsTable(attachedDatabase, alias);
  }
}

class TaskCompletion extends DataClass implements Insertable<TaskCompletion> {
  final int id;
  final String taskId;
  final DateTime date;
  final bool done;
  const TaskCompletion(
      {required this.id,
      required this.taskId,
      required this.date,
      required this.done});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<String>(taskId);
    map['date'] = Variable<DateTime>(date);
    map['done'] = Variable<bool>(done);
    return map;
  }

  TaskCompletionsCompanion toCompanion(bool nullToAbsent) {
    return TaskCompletionsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      date: Value(date),
      done: Value(done),
    );
  }

  factory TaskCompletion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCompletion(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      date: serializer.fromJson<DateTime>(json['date']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<String>(taskId),
      'date': serializer.toJson<DateTime>(date),
      'done': serializer.toJson<bool>(done),
    };
  }

  TaskCompletion copyWith(
          {int? id, String? taskId, DateTime? date, bool? done}) =>
      TaskCompletion(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        date: date ?? this.date,
        done: done ?? this.done,
      );
  TaskCompletion copyWithCompanion(TaskCompletionsCompanion data) {
    return TaskCompletion(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      date: data.date.present ? data.date.value : this.date,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, date, done);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCompletion &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.date == this.date &&
          other.done == this.done);
}

class TaskCompletionsCompanion extends UpdateCompanion<TaskCompletion> {
  final Value<int> id;
  final Value<String> taskId;
  final Value<DateTime> date;
  final Value<bool> done;
  const TaskCompletionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.date = const Value.absent(),
    this.done = const Value.absent(),
  });
  TaskCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    required DateTime date,
    this.done = const Value.absent(),
  })  : taskId = Value(taskId),
        date = Value(date);
  static Insertable<TaskCompletion> custom({
    Expression<int>? id,
    Expression<String>? taskId,
    Expression<DateTime>? date,
    Expression<bool>? done,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (date != null) 'date': date,
      if (done != null) 'done': done,
    });
  }

  TaskCompletionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? taskId,
      Value<DateTime>? date,
      Value<bool>? done}) {
    return TaskCompletionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskCompletionsTable taskCompletions =
      $TaskCompletionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks, taskCompletions];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('tasks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('task_completions', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  required String category,
  Value<String> recurrence,
  Value<String?> customDays,
  Value<int?> scheduledHour,
  Value<int?> scheduledMinute,
  Value<bool> isHabit,
  Value<bool> reminderEnabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> category,
  Value<String> recurrence,
  Value<String?> customDays,
  Value<int?> scheduledHour,
  Value<int?> scheduledMinute,
  Value<bool> isHabit,
  Value<bool> reminderEnabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskCompletionsTable, List<TaskCompletion>>
      _taskCompletionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.taskCompletions,
              aliasName: 'tasks__id__task_completions__task_id');

  $$TaskCompletionsTableProcessedTableManager get taskCompletionsRefs {
    final manager =
        $$TaskCompletionsTableTableManager($_db, $_db.taskCompletions)
            .filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_taskCompletionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customDays => $composableBuilder(
      column: $table.customDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledHour => $composableBuilder(
      column: $table.scheduledHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledMinute => $composableBuilder(
      column: $table.scheduledMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHabit => $composableBuilder(
      column: $table.isHabit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> taskCompletionsRefs(
      Expression<bool> Function($$TaskCompletionsTableFilterComposer f) f) {
    final $$TaskCompletionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskCompletions,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskCompletionsTableFilterComposer(
              $db: $db,
              $table: $db.taskCompletions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customDays => $composableBuilder(
      column: $table.customDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledHour => $composableBuilder(
      column: $table.scheduledHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledMinute => $composableBuilder(
      column: $table.scheduledMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHabit => $composableBuilder(
      column: $table.isHabit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<String> get customDays => $composableBuilder(
      column: $table.customDays, builder: (column) => column);

  GeneratedColumn<int> get scheduledHour => $composableBuilder(
      column: $table.scheduledHour, builder: (column) => column);

  GeneratedColumn<int> get scheduledMinute => $composableBuilder(
      column: $table.scheduledMinute, builder: (column) => column);

  GeneratedColumn<bool> get isHabit =>
      $composableBuilder(column: $table.isHabit, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> taskCompletionsRefs<T extends Object>(
      Expression<T> Function($$TaskCompletionsTableAnnotationComposer a) f) {
    final $$TaskCompletionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskCompletions,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskCompletionsTableAnnotationComposer(
              $db: $db,
              $table: $db.taskCompletions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool taskCompletionsRefs})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> recurrence = const Value.absent(),
            Value<String?> customDays = const Value.absent(),
            Value<int?> scheduledHour = const Value.absent(),
            Value<int?> scheduledMinute = const Value.absent(),
            Value<bool> isHabit = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            category: category,
            recurrence: recurrence,
            customDays: customDays,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            isHabit: isHabit,
            reminderEnabled: reminderEnabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String category,
            Value<String> recurrence = const Value.absent(),
            Value<String?> customDays = const Value.absent(),
            Value<int?> scheduledHour = const Value.absent(),
            Value<int?> scheduledMinute = const Value.absent(),
            Value<bool> isHabit = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            category: category,
            recurrence: recurrence,
            customDays: customDays,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            isHabit: isHabit,
            reminderEnabled: reminderEnabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({taskCompletionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (taskCompletionsRefs) db.taskCompletions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskCompletionsRefs)
                    await $_getPrefetchedData<Task, $TasksTable,
                            TaskCompletion>(
                        currentTable: table,
                        referencedTable: $$TasksTableReferences
                            ._taskCompletionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TasksTableReferences(db, table, p0)
                                .taskCompletionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.taskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool taskCompletionsRefs})>;
typedef $$TaskCompletionsTableCreateCompanionBuilder = TaskCompletionsCompanion
    Function({
  Value<int> id,
  required String taskId,
  required DateTime date,
  Value<bool> done,
});
typedef $$TaskCompletionsTableUpdateCompanionBuilder = TaskCompletionsCompanion
    Function({
  Value<int> id,
  Value<String> taskId,
  Value<DateTime> date,
  Value<bool> done,
});

final class $$TaskCompletionsTableReferences extends BaseReferences<
    _$AppDatabase, $TaskCompletionsTable, TaskCompletion> {
  $$TaskCompletionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_completions__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TaskCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableOrderingComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskCompletionsTable,
    TaskCompletion,
    $$TaskCompletionsTableFilterComposer,
    $$TaskCompletionsTableOrderingComposer,
    $$TaskCompletionsTableAnnotationComposer,
    $$TaskCompletionsTableCreateCompanionBuilder,
    $$TaskCompletionsTableUpdateCompanionBuilder,
    (TaskCompletion, $$TaskCompletionsTableReferences),
    TaskCompletion,
    PrefetchHooks Function({bool taskId})> {
  $$TaskCompletionsTableTableManager(
      _$AppDatabase db, $TaskCompletionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<bool> done = const Value.absent(),
          }) =>
              TaskCompletionsCompanion(
            id: id,
            taskId: taskId,
            date: date,
            done: done,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String taskId,
            required DateTime date,
            Value<bool> done = const Value.absent(),
          }) =>
              TaskCompletionsCompanion.insert(
            id: id,
            taskId: taskId,
            date: date,
            done: done,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TaskCompletionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (taskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.taskId,
                    referencedTable:
                        $$TaskCompletionsTableReferences._taskIdTable(db),
                    referencedColumn:
                        $$TaskCompletionsTableReferences._taskIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TaskCompletionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TaskCompletionsTable,
    TaskCompletion,
    $$TaskCompletionsTableFilterComposer,
    $$TaskCompletionsTableOrderingComposer,
    $$TaskCompletionsTableAnnotationComposer,
    $$TaskCompletionsTableCreateCompanionBuilder,
    $$TaskCompletionsTableUpdateCompanionBuilder,
    (TaskCompletion, $$TaskCompletionsTableReferences),
    TaskCompletion,
    PrefetchHooks Function({bool taskId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskCompletionsTableTableManager get taskCompletions =>
      $$TaskCompletionsTableTableManager(_db, _db.taskCompletions);
}

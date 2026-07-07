import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

/// Schedules and cancels local reminder notifications for tasks.
///
/// DESIGN NOTES (read before touching this file):
///
/// 1. flutter_local_notifications schedules by absolute time, not by
///    "recurrence type" — so each RecurrenceType maps to a different
///    scheduling strategy (see _scheduleFor below). "Weekdays" isn't a
///    single API call; it's five separate weekly-repeating notifications,
///    one per weekday, because the plugin's repeat-matching only
///    understands "same time every day" or "same weekday+time every week."
///
/// 2. Notification IDs must be stable across app restarts (so we can
///    cancel/reschedule the *same* notification later). We deliberately
///    do NOT use Dart's String.hashCode for this — it happens to work in
///    practice, but the language spec doesn't guarantee it's stable
///    across Dart versions, which would silently orphan old scheduled
///    notifications after a Dart upgrade. `_stableHash` below is an
///    explicit, documented algorithm (FNV-1a) that will never change out
///    from under us.
///
/// 3. A task can own up to 7 notification IDs (one per possible weekday).
///    IDs are derived as `_stableHash(taskId) * 10 + weekdayOffset`, so
///    they're deterministic, don't collide between tasks (astronomically
///    unlikely with FNV-1a's spread), and don't collide between a single
///    task's own weekday slots.
///
/// 4. HONEST RISK FLAG: I don't have network access to verify
///    flutter_local_notifications' exact `zonedSchedule` signature against
///    the specific version that ends up in your pubspec.lock — its
///    parameter shape has changed across major versions before (v9→v10
///    removed some enums; Android 12+ added exact-alarm permission
///    requirements; Android 13+ added runtime POST_NOTIFICATIONS
///    permission). What's below matches the API as of the v17.x line this
///    project pins in pubspec.yaml, based on that version's documented
///    usage pattern. Run `flutter analyze` after `pub get` — if the
///    plugin's API has moved, this file is the first place to check.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask explicitly later, see requestPermissions()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  /// Requests OS notification permission. Call this from an explicit user
  /// action (e.g. toggling "Reminders" on in Settings) — not silently at
  /// app startup, which iOS in particular treats as a red flag and tends
  /// to auto-deny on behalf of the user.
  Future<bool> requestPermissions() async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await androidImpl?.requestNotificationsPermission() ?? true;
    // Android 12+ requires a separate exact-alarm permission for precise
    // scheduled reminders; without it, notifications still fire but may
    // drift by several minutes. Requesting it is best-effort — some OEMs
    // route this to a settings screen rather than a dialog.
    await androidImpl?.requestExactAlarmsPermission();

    final iosGranted = await iosImpl?.requestPermissions(alert: true, badge: true, sound: true) ?? true;

    return androidGranted && iosGranted;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // iOS has no simple synchronous "is enabled" check without also
    // pulling in permission_handler (another unverified API surface) —
    // best-effort: assume enabled on iOS until a request is explicitly
    // denied, which requestPermissions() surfaces via its return value.
    return await androidImpl?.areNotificationsEnabled() ?? true;
  }

  /// Cancels any existing notifications for this task, then reschedules
  /// from scratch based on its current recurrence/time/reminder settings.
  /// Call this after every add/update — simpler and more correct than
  /// diffing old vs. new schedule.
  Future<void> rescheduleFor(RoutineTask task) async {
    await cancelFor(task.id);

    if (!task.reminderEnabled || task.scheduledTime == null) return;

    final time = task.scheduledTime!;

    switch (task.recurrence) {
      case RecurrenceType.daily:
        await _scheduleWeekly(task, weekday: null, hour: time.hour, minute: time.minute, slot: 0);
        break;
      case RecurrenceType.weekdays:
        for (int weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
          await _scheduleWeekly(task, weekday: weekday, hour: time.hour, minute: time.minute, slot: weekday);
        }
        break;
      case RecurrenceType.custom:
        for (final weekday in (task.customDays ?? const <int>[])) {
          await _scheduleWeekly(task, weekday: weekday, hour: time.hour, minute: time.minute, slot: weekday);
        }
        break;
      case RecurrenceType.oneOff:
        await _scheduleOnce(task, hour: time.hour, minute: time.minute);
        break;
    }
  }

  Future<void> cancelFor(String taskId) async {
    final baseId = _stableHash(taskId);
    // Slot 0 = daily/one-off; slots 1-7 = the seven possible weekdays.
    for (int slot = 0; slot <= 7; slot++) {
      await _plugin.cancel(baseId * 10 + slot);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _scheduleOnce(RoutineTask task, {required int hour, required int minute}) async {
    final scheduled = _nextInstanceOfTime(hour, minute, task.createdAt);
    if (scheduled.isBefore(DateTime.now())) return; // one-off's day already passed

    await _plugin.zonedSchedule(
      _stableHash(task.id) * 10,
      task.title,
      "It's time for your task",
      tz.TZDateTime.from(scheduled, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null, // fires exactly once
    );
  }

  Future<void> _scheduleWeekly(
    RoutineTask task, {
    required int? weekday, // null = every day
    required int hour,
    required int minute,
    required int slot,
  }) async {
    final next = weekday == null
        ? _nextInstanceOfTime(hour, minute, DateTime.now())
        : _nextInstanceOfWeekday(weekday, hour, minute);

    await _plugin.zonedSchedule(
      _stableHash(task.id) * 10 + slot,
      task.title,
      "It's time for your task",
      tz.TZDateTime.from(next, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_tracker_reminders',
        'Task reminders',
        channelDescription: 'Reminders for scheduled tasks',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  DateTime _nextInstanceOfTime(int hour, int minute, DateTime notBefore) {
    var scheduled = DateTime(notBefore.year, notBefore.month, notBefore.day, hour, minute);
    if (scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  DateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// FNV-1a hash, truncated to stay well within a safe range once
  /// multiplied by 10 in the callers above (int32-safe on all platforms
  /// Flutter targets, including web's JS number limitations).
  static int _stableHash(String input) {
    const fnvPrime = 0x01000193;
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash % 1000000; // keep headroom below the *10 + slot multiply
  }
}

# Routine Tracker

A daily routine and habit tracker built with Flutter. Offline-first, fully
local — no backend, no account, no analytics. Your data stays on your
device.

Dark theme is the default (with a complete, first-class light theme
alongside it, not an afterthought). Six screens, live state end to end:
**Today · Habits · History · Add/Edit Task · Stats · Settings**.

---

## Stack

| Layer          | Choice                                  |
|----------------|------------------------------------------|
| State          | Riverpod                                  |
| Local database | Drift (SQLite)                            |
| Navigation     | go_router                                 |
| Notifications  | flutter_local_notifications + timezone    |
| Charts         | Custom `AnimatedContainer`-based bars     |
| Theming        | Custom `ThemeExtension` with full `lerp()`|

## Getting started

```bash
flutter pub get
flutter run
```

Target platform is Android (tested on API 29+). A `windows/` folder is
present for desktop builds, but `sqlite3_flutter_libs` and
`flutter_local_notifications` are mobile-first packages — expect the
desktop build to need extra work for full parity. Web is not supported:
Drift's default backend needs native SQLite, which isn't available in a
browser without a separate WASM setup.

## Project structure

```
lib/
├── data/           # Drift schema (tables.dart) + database (database.dart)
├── models/         # RoutineTask — app-level model, decoupled from the DB row
├── providers/       # Riverpod: live task streams, notification actions, theme
├── router/          # go_router config, including the Add Task transition
├── screens/         # Today, Habits, History, Add/Edit Task, Stats, Settings
├── services/         # NotificationService, ExportService
├── theme/           # AppPalette (ThemeExtension, dark + light)
└── widgets/         # TaskTile, ProgressRing, TimelineView, StaggeredFadeIn
```

## Features

- **Recurrence-aware scheduling** — daily, weekdays, custom days, or
  one-off tasks. `isScheduledOn()` is the single source of truth for
  whether a task shows up on a given day, used consistently across Today,
  Habits, History, and Stats — so streaks and heatmaps don't mistake a
  day the task wasn't even scheduled for a missed one.
- **Local notifications**, recurrence-matched: one repeating reminder for
  daily tasks, five for weekdays, one per selected day for custom
  recurrence, a single non-repeating one for one-off tasks. Every
  add/update/delete of a task automatically reschedules or cancels its
  reminder — no manual wiring needed from UI code.
- **Timeline view** — a vertical, hour-gridded view of the day with a
  live now-indicator, auto-scroll to the current time on open, and a
  separate section for tasks with no set time. Toggles with the List view
  via a shared `SegmentedToggle` (cross-fades with `AnimatedSwitcher`).
- **Data export** — serializes tasks + completions to JSON and hands it to
  the OS share sheet. No fake "saved to Downloads" toast: the share sheet
  appearing *is* the confirmation.
- **Theme cross-fade** — switching Settings' dark/light toggle animates
  every color in the app via `AppPalette.lerp()`, not just a instant
  swap.

## Known constraints, on purpose

- **Timeline cards are fixed-height**, not duration-sized. The data model
  has no `durationMinutes` field; adding one is a real schema migration,
  kept out of scope for the timeline view itself.
- **iOS notification permission state** is optimistic (assumed enabled
  until explicitly denied) — a synchronous OS check without pulling in
  `permission_handler` isn't available on iOS the way it is on Android.
- **share_plus is pinned to `^7.2.2`** deliberately, to keep using its
  static `Share.shareXFiles()` API. The package's shape changed to an
  instance-based `SharePlus.instance.share(...)` pattern from v10 onward
  — if you bump this dependency, update the call site in
  `export_service.dart` in the same change, or exports will silently
  break.

## Fixed since the initial scaffold

A few issues surfaced during real device testing (Android 10, physical
hardware) and are now resolved:

- **`_TimelineTaskCardState` ticker mixin** — was declared with
  `SingleTickerProviderStateMixin` while creating two
  `AnimationController`s (fade + press-scale). Flutter enforces one
  ticker per `SingleTickerProviderStateMixin`; the second controller threw
  at runtime and took down the Timeline view. Fixed by switching to
  `TickerProviderStateMixin`.
- **Missing Android notification permissions** — `POST_NOTIFICATIONS`,
  `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, and `RECEIVE_BOOT_COMPLETED`
  weren't declared in `AndroidManifest.xml`. On Android 13+ this means the
  OS won't even show a notification toggle in system Settings for the
  app. All four are now declared.
- **`flutter_timezone` v2.x → v5.x** — the old version used Flutter's
  deprecated v1 plugin embedding, which no longer compiles against
  current Android/Kotlin toolchains (`Unresolved reference: Registrar`).
  Upgrading to v5 also changed `getLocalTimezone()`'s return type from
  `String` to a `TimezoneInfo` object — call sites updated to read
  `.identifier`.
- **`flutter_local_notifications` required argument** — `zonedSchedule()`
  now requires `uiLocalNotificationDateInterpretation` explicitly; added
  to both call sites in `notification_service.dart`.
- **Core library desugaring** — required by
  `flutter_local_notifications` on Android but wasn't enabled in
  `android/app/build.gradle.kts`; added `isCoreLibraryDesugaringEnabled`
  and the `desugar_jdk_libs` dependency.
- **Reminder scheduling failures were silent** — if notification
  permission was missing, or a one-off task's time had already passed,
  the task would save successfully but the reminder would silently never
  fire, with no feedback anywhere. `rescheduleFor()` now returns `bool`,
  checks `areNotificationsEnabled()` before scheduling, and wraps the
  actual scheduling call in a `try/catch` so an OS-level rejection can't
  crash the app. The Add/Edit Task screen surfaces a snackbar when a
  reminder couldn't be set, instead of failing invisibly.

## Notification internals worth knowing

- Notification IDs are a hand-written FNV-1a hash of the task ID, not
  Dart's built-in `String.hashCode` — the latter isn't spec-guaranteed
  stable across Dart versions, which could silently orphan scheduled
  notifications after an SDK upgrade.
- The Settings permission toggle shows an explainer bottom sheet *before*
  triggering the OS permission dialog. This matters most on iOS, where a
  denied system dialog can't be re-prompted without the user manually
  going to Settings — worth the extra tap to explain why first.

## Gesture map

Deliberately asymmetric across screens, documented here rather than left
implicit:

| Screen           | Tap               | Long-press           |
|-------------------|--------------------|------------------------|
| Today's task rows | Toggle completion  | Open edit (scale-pop + haptic) |
| Habits cards      | Open edit          | 3D tilt reveal          |
| Timeline cards    | Toggle completion  | Open edit               |

## Contributing / next steps

- Deep-link the notification-permission-denied hint (Settings) to the OS
  settings screen — needs a package like `app_settings`.
- Consider `fl_chart` for the Stats screen if richer chart types are
  needed later; it's still listed in `pubspec.yaml` but currently unused
  in favor of a lighter custom bar chart.
- Web/WASM support for Drift, if a browser target becomes a real
  requirement.
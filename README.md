# Routine Tracker — Flutter starter

Dark, moody theme baked in as the default (with a fully real light theme
alongside it). All six screens are wired up with live Riverpod + Drift
state: Today, Habits, History, Add/Edit Task, Stats, and Settings —
matching the approved design mockups and animation specs.

## Setup

```bash
flutter create . --platforms=android,ios   # only if you didn't use `flutter create` already
flutter pub get
flutter run
```

If you're starting completely fresh instead of dropping these files into
an existing project:

```bash
flutter create routine_tracker
# then copy pubspec.yaml and lib/ from this folder into the new project,
# overwriting the defaults
cd routine_tracker
flutter pub get
flutter run
```

## What's included

- `lib/theme/app_theme.dart` — `AppPalette`, a proper `ThemeExtension` with
  full `lerp()` support for both dark and light palettes (not static
  dark-only constants) — this is what makes the Settings screen's theme
  cross-fade actually work correctly across every color in the app
- `lib/models/task.dart` — `RoutineTask` (with `createdAt`, used to
  correctly exclude days before a task existed from completion-rate math)
- `lib/data/` — Drift schema (`tables.dart`) + database (`database.dart`)
- `lib/providers/task_provider.dart` — live Riverpod streams from Drift
- `lib/providers/theme_provider.dart` — persisted theme mode (SharedPreferences,
  loaded before first frame — no flash-of-wrong-theme on cold start)
- `lib/screens/` — all six screens implemented: Today, Habits, History,
  Add/Edit Task, Stats, Settings
- `lib/widgets/` — `TaskTile`, `ProgressRing`, `StaggeredFadeIn`

## Honest flags — things to verify before you trust this blindly

I don't have network access to pub.dev from this sandbox, so I couldn't
verify a few third-party API surfaces. Rather than guess and risk shipping
broken code, I made deliberate substitutions:

- **Stats chart**: built as a small custom `AnimatedContainer`-based bar
  chart instead of `fl_chart`'s `BarChart`, since that package's
  constructor API varies across versions. `fl_chart` is still in
  `pubspec.yaml` if you'd rather wire it up for more chart features later.
- **All animations**: built with core Flutter (`AnimationController`,
  `Tween`, `Curves`, `TweenSequence`) rather than `flutter_animate`'s
  chained API, for the same reason. `flutter_animate` was dropped from
  `pubspec.yaml` since nothing in the code actually uses it — no point
  carrying an unused dependency.
- **~~Icon names~~**: this one actually broke, for real, when you ran
  `flutter pub get` — `tabler_icons_flutter: ^0.0.11` doesn't exist as a
  resolvable version (the package is at a `2.x` major version now). That's
  exactly the risk this section warned about, now confirmed rather than
  hypothetical. **Fixed properly, not patched**: rather than bump the
  version constraint and hope the icon names in `2.x` still matched my
  guesses (trading one unverified guess for another), every icon in the
  project now uses Flutter's own built-in `Icons` class (Material
  Symbols) — `tabler_icons_flutter` is fully removed from `pubspec.yaml`.
  Zero version risk, zero third-party API surface, guaranteed to compile.
  The visual style changed slightly (Material Symbols vs. Tabler's
  thinner outline style) but every icon's *meaning* is preserved
  one-for-one — see the mapping table in `pubspec.yaml`'s comment if you
  want to swap any individual icon back to a specific outline set later.
- **Notification permission state** (Settings screen) — **now real**, not
  hardcoded. `NotificationService.areNotificationsEnabled()` checks actual
  OS state on Android; iOS has no simple synchronous check without also
  pulling in `permission_handler`, so it optimistically assumes enabled
  there until a request is explicitly denied.
- **share_plus** (data export): pinned to `^7.2.2` specifically to use its
  older static `Share.shareXFiles()` API — this package's API shape
  changed to an instance-based `SharePlus.instance.share(...)` pattern in
  its v10 line, and I don't have network access to confirm which is
  "current" right now. The version pin and the API call must stay
  consistent with each other; if you bump this package's version, check
  this before anything else breaks confusingly.
- **~~Navigation~~**: resolved. `go_router` is now actually wired
  (`lib/router/app_router.dart`) rather than sitting unused in
  `pubspec.yaml` — see "Next steps" below for what changed.

## Next steps

1. Run `flutter pub get`, then `flutter analyze`. Icon names are no
   longer a risk (see above), so **check `lib/services/notification_service.dart`
   first** if anything's wrong — that's the single highest-risk file left
   in the project (see the risk flag further down).
2. Deep-link "Open" button in the notification-permission-denied hint
   (Settings) to the OS settings app — needs a package like `app_settings`,
   deliberately left as a TODO for the same reason as other unverified APIs.

~~4. Timeline view~~ — **done.** `lib/widgets/timeline_view.dart` renders
   a vertical hour-gridded timeline with a live, minute-updating
   now-indicator, auto-scrolls to the current time on open, and shows
   tasks with no time set in a separate section below (per spec — they
   never appear ON the timeline itself). List/Timeline is a shared
   `SegmentedToggle` widget (extracted so it isn't duplicated with Stats'
   7/30-day control), cross-fading via `AnimatedSwitcher`.
   **One explicit scope decision**: tasks render as fixed-height cards
   positioned at their start time, not duration-sized blocks — the data
   model has no `durationMinutes` field, and adding one means a real Drift
   schema migration, which is separate work from "add the timeline view."

~~5. Custom recurrence's `customDays` isn't yet used to filter which days a
   task actually shows up on~~ — **done.** `isScheduledOn()` in
   `task_provider.dart` is now the single source of truth for whether a
   task appears on a given day, and every screen (Today, Habits, History,
   Stats) filters through it. This also fixed `currentStreak()` (it now
   skips non-scheduled days instead of treating them as streak-breakers)
   and the Habits mini-heatmap (not-scheduled days now render as a faint
   dashed square instead of looking like a missed day).

~~6. Notifications~~ — **done.** See below.

~~7. Wire up the actual data export~~ — **done.** `lib/services/export_service.dart`
   serializes tasks + completions to JSON and hands it to the OS share
   sheet via `share_plus`. **Note the UI behavior changed to match reality**:
   the original spec said "Exported to Downloads," which isn't a simple,
   reliable operation on iOS at all — the honest mobile pattern is
   "build the file, hand it to the share sheet, let the user pick where
   it goes." No success toast after sharing, on purpose: the share sheet
   appearing IS the confirmation, and there's no reliable way to
   distinguish "shared" from "cancelled" without more complexity than a
   toast is worth.

~~8. Navigation uses plain Navigator instead of go_router~~ — **done.**
   `lib/router/app_router.dart` now handles both real navigation actions
   (Add/Edit Task, Settings) via `go_router`, including the slide-up+fade
   transition for Add Task (moved from a hand-rolled `PageRouteBuilder`
   into a `CustomTransitionPage` — same visual result, real dependency
   now). This app only has two navigation actions, which is exactly why
   this was worth doing properly rather than leaving it flagged: the
   surface area to get wrong was small.

~~9. There's no UI entry point anywhere that opens Add Task in edit mode~~
   — **done.** Gesture mapping is deliberately asymmetric across screens,
   documented in each file rather than left implicit:
   - **Today's task rows**: tap toggles completion (unchanged) →
     **long-press opens edit** (new) — a brief scale-pop + medium haptic
     confirms the gesture landed before the screen transitions, so it
     doesn't feel like an accidental navigation.
   - **Habits cards**: long-press was already reserved for the 3D tilt
     reveal (an earlier, deliberate decision) → **tap opens edit** (new),
     kept crisp/instant with no pre-animation, since the more elaborate
     confirming gesture is spoken for elsewhere on the same card.
   - **Timeline task cards**: same long-press-to-edit as Today's list,
     since it's the same underlying tasks in a different view.

**Still open**: the `fl_chart` question above.

## Notifications — what's implemented and the risk that comes with it

`lib/services/notification_service.dart` schedules real, recurrence-aware
local notifications:

- **daily** → one notification, repeats every day at that time
- **weekdays** → five separate notifications (Mon–Fri), each repeating weekly
- **custom** → one notification per selected day, same weekly-repeat approach
- **one-off** → a single non-repeating notification

Every add/update/delete of a task goes through `TaskActions`, which calls
`NotificationService.rescheduleFor()` / `.cancelFor()` automatically — you
don't need to call the notification service directly from UI code.

**Two things I got right on purpose, worth knowing about:**
- Notification IDs use a hand-written FNV-1a hash of the task ID, not
  Dart's `String.hashCode` — the latter works in practice but isn't
  spec-guaranteed stable across Dart versions, which would silently
  orphan old scheduled notifications after a Dart upgrade.
- The Settings permission toggle shows an explainer bottom sheet *before*
  triggering the OS permission dialog — this matters specifically on iOS,
  where a denied system dialog can't be re-shown to the user without them
  manually going to Settings, so it's worth spending the extra tap to
  explain why first.

**The honest risk**: I don't have network access to verify
`flutter_local_notifications`' exact API against whatever version actually
resolves in your `pubspec.lock`. The `zonedSchedule` signature, the
Android 12+ exact-alarm permission flow, and the Android 13+ runtime
notification permission have all changed shape across this plugin's
major versions before. What's implemented matches the documented v17.x
pattern as I understand it — but this is the single file in the project
most likely to need a small signature fix after `flutter pub get`. Start
`flutter analyze` here if anything's going to be wrong.



## Notes

- The dark palette is the primary/default theme (`ThemeMode.dark` is the
  fallback if no saved preference exists), matching the original design
  decision — but light mode is now a fully real, complete second theme,
  not an afterthought.


# Animation & Motion Reference

These are the approved motion-design specs for RoutineTracker, agreed on
before implementation. They're the source of truth for timing, curves,
and the 3D-depth policy per screen — refer back to these instead of
guessing at values while building.

| File | Covers |
|---|---|
| `01-today-progress-ring.png` | Today screen — progress ring arc animation (`Tween<double>`), task-toggle scale pop, `AnimatedList` for the task list |
| `02-timing-tokens-packages-3d.png` | Global timing tokens (150/250/500-700ms + curves), package decisions (`flutter_animate` + Flutter built-ins, **no Lottie/Rive**), the 3D card-press technique (`Matrix4` + perspective), and the Reduce Motion policy |
| `03-habits-loadin-milestone-tilt.png` | Habits screen — staggered fade-up load-in (~40ms per card), streak-milestone pulse (scale + color, no confetti), long-press 3D tilt (~4°, springs back on release) |
| `04-calendar-nav-day-detail.png` | History screen — month `PageView` transitions (300ms), day-detail card expansion (`AnimatedSize` + fade), selected-cell scale-up (1.0→1.1→1.0). **No 3D depth on this screen** — calendar is a fast lookup tool |
| `05-calendar-form-interactions.png` | Add/Edit Task screen — form presentation (slide up + fade, 300ms), category chip selection animation, custom-recurrence day-toggle grow-in, Save button 3D press-depth (scale 0.97 + perspective tilt, `Curves.elasticOut`) |
| `06-stats-chart-3d-depth.png` | Stats screen — bar chart grow-from-baseline (500ms), 7/30-day segmented control slide (200ms), the one screen with a tasteful 3D moment (stat cards tilt via gyroscope OR scroll position — treat gyroscope as optional v1.1) |
| `07-settings-theme-crossfade.png` | Settings screen — `AnimatedTheme` cross-fade (300ms) on theme mode switch, standard `Switch` animation for toggle rows. **No 3D depth** — Settings is a utility screen, motion should be functional only |

## Non-negotiables across every screen

- **Reduce Motion**: every custom animation must check
  `MediaQuery.of(context).disableAnimations` and jump straight to the
  end-state if true.
- **No Lottie/Rive**: motion is built with `flutter_animate` + Flutter's
  own implicit animations + `CustomPainter` — keep the dependency
  footprint small.
- **3D depth is intentional, not universal**: only Habits (long-press
  tilt), Add Task (Save button press), and Stats (card tilt) get it.
  Today, History, and Settings stay flat by design — see the "NO 3D
  DEPTH POLICY" callouts in the History and Settings images.

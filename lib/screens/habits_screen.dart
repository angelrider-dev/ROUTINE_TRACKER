import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/staggered_fade_in.dart';

const _milestones = [7, 30, 100];

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final completionsAsync = ref.watch(completionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Habits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Expanded(
                child: tasksAsync.when(
                  data: (allTasks) {
                    final habits = allTasks.where((t) => t.isHabit).toList();
                    return completionsAsync.when(
                      data: (completions) => _HabitsBody(
                        habits: habits,
                        allTasksIsEmpty: allTasks.isEmpty,
                        completions: completions,
                      ),
                      loading: () => const _Skeleton(),
                      error: (_, __) => const _ErrorBanner(),
                    );
                  },
                  loading: () => const _Skeleton(),
                  error: (_, __) => const _ErrorBanner(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitsBody extends StatelessWidget {
  final List<RoutineTask> habits;
  final bool allTasksIsEmpty;
  final Map<String, bool> completions;

  const _HabitsBody({required this.habits, required this.allTasksIsEmpty, required this.completions});

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return _EmptyState(noTasksAtAll: allTasksIsEmpty);

    final palette = context.palette;
    final streaks = {for (final h in habits) h.id: currentStreak(habits, completions, h.id)};
    final bestStreak = streaks.values.isEmpty ? 0 : streaks.values.reduce(max);
    final thisWeekPct = _thisWeekPercent(habits, completions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '$thisWeekPct%',
                label: 'This week',
                tint: palette.greenTint,
                valueColor: palette.greenAccent,
                labelColor: palette.greenText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$bestStreak',
                label: 'Best streak',
                tint: palette.amberTint,
                valueColor: palette.amberAccent,
                labelColor: palette.amberText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return StaggeredFadeIn(
                index: index,
                child: _HabitCard(task: habit, streak: streaks[habit.id] ?? 0, completions: completions),
              );
            },
          ),
        ),
      ],
    );
  }

  int _thisWeekPercent(List<RoutineTask> habits, Map<String, bool> completions) {
    if (habits.isEmpty) return 0;
    int done = 0;
    int scheduled = 0;
    for (final h in habits) {
      for (int i = 0; i < 7; i++) {
        final day = DateTime.now().subtract(Duration(days: i));
        if (!isScheduledOn(h, day)) continue;
        scheduled++;
        if (isDoneOn(completions, h.id, day)) done++;
      }
    }
    if (scheduled == 0) return 0;
    return ((done / scheduled) * 100).round();
  }
}

/// A single habit card: streak pill + 7-day mini heatmap.
/// - Pulses (scale + color brighten, 400ms) the moment its streak crosses
///   a milestone (7 / 30 / 100 days), with a medium haptic impact.
/// - Tilts in 3D (~4°, Matrix4 perspective) on long-press, springing back
///   on release via Curves.elasticOut. This is the ONE place on this
///   screen depth is used — deliberately, not decoratively everywhere.
class _HabitCard extends StatefulWidget {
  final RoutineTask task;
  final int streak;
  final Map<String, bool> completions;

  const _HabitCard({required this.task, required this.streak, required this.completions});

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> with TickerProviderStateMixin {
  late final AnimationController _milestoneController;
  late final AnimationController _tiltController;
  int? _previousStreak;

  @override
  void initState() {
    super.initState();
    _milestoneController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 450),
    );
    _previousStreak = widget.streak;
  }

  @override
  void didUpdateWidget(covariant _HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final crossedMilestone = _milestones.any((m) => (_previousStreak ?? 0) < m && widget.streak >= m);
    if (crossedMilestone) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      HapticFeedback.mediumImpact();
      if (!reduceMotion) _milestoneController.forward(from: 0);
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    HapticFeedback.lightImpact();
    _tiltController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) => _tiltController.reverse();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final category = widget.task.category;

    return GestureDetector(
      // Deliberately asymmetric with Today's task rows: long-press here is
      // already spoken for by the tilt reveal below, so edit lives on tap
      // instead — kept crisp/instant (no pre-animation) since the more
      // elaborate confirming gesture is reserved for long-press.
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/add-task', extra: widget.task);
      },
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: () => _tiltController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_milestoneController, _tiltController]),
        builder: (context, child) {
          final tilt = Curves.easeOut.transform(_tiltController.value);
          final pulse = _milestoneController.value == 0 ? 0.0 : sin(_milestoneController.value * pi);

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-4 * (pi / 180) * tilt)
            ..rotateY(4 * (pi / 180) * tilt)
            ..scale(1.0 - (0.02 * tilt) + (0.03 * pulse));

          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.lerp(palette.surfaceRaised, palette.purpleTint, pulse * 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border, width: 0.5),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(category.icon, size: 16, color: category.accent(palette)),
                    const SizedBox(width: 8),
                    Text(widget.task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                Semantics(
                  label: '${widget.streak} day streak',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: palette.amberTint, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, size: 12, color: palette.amberAccent),
                        const SizedBox(width: 3),
                        Text('${widget.streak}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: palette.amberText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final day = DateTime.now().subtract(Duration(days: 6 - i));
                final scheduled = isScheduledOn(widget.task, day);
                final done = scheduled && isDoneOn(widget.completions, widget.task.id, day);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Semantics(
                    label: '${_weekdayFull(day.weekday)}, ${_ordinal(day.day)}, '
                        '${!scheduled ? 'not scheduled' : done ? 'completed' : 'missed'}',
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        // Not-scheduled days (e.g. weekends for a
                        // weekdays-only habit) get a faint dashed-look
                        // border instead of the "missed" solid border
                        // color — so the habit doesn't look like it
                        // failed on a day it was never supposed to run.
                        color: done ? palette.greenAccent : Colors.transparent,
                        border: !scheduled
                            ? Border.all(color: palette.border.withOpacity(0.4), width: 1)
                            : (done ? null : Border.all(color: palette.border, width: 1)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayFull(int weekday) =>
      const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color tint;
  final Color valueColor;
  final Color labelColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.tint,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool noTasksAtAll;
  const _EmptyState({required this.noTasksAtAll});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 40, color: palette.textMuted),
          const SizedBox(height: 12),
          Text('No habits yet', style: TextStyle(fontSize: 14, color: palette.textSecondary)),
          const SizedBox(height: 4),
          Text(
            noTasksAtAll ? 'Add a task first, then mark it as a habit' : 'Mark a task as a habit to see it here',
            style: TextStyle(fontSize: 12, color: palette.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => Container(
        height: 70,
        decoration: BoxDecoration(color: palette.surfaceRaised, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: palette.coralTint, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: palette.coralAccent),
          const SizedBox(width: 8),
          Text("Couldn't load habits", style: TextStyle(fontSize: 12, color: palette.coralText)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/staggered_fade_in.dart';

/// Stats screen — completion trends + top habits.
///
/// NOTE ON THE CHART: this uses a small custom bar-chart widget rather
/// than fl_chart's BarChart. fl_chart is still in pubspec.yaml for future
/// use, but its exact constructor API varies across versions and I can't
/// verify it without network access to pub.dev from this environment —
/// guessing at a third-party API and shipping it unverified is a worse
/// risk than a few dozen lines of custom, fully-understood widget code
/// that's guaranteed to compile and behaves identically for this case.
///
/// Animations (see docs/animation-reference/06-stats-chart-3d-depth.png):
/// - bars grow from 0% baseline, 500ms Curves.easeOutCubic
/// - segmented control indicator slides between 7/30 day options, 200ms
/// - stat cards get a tasteful 3D press-tilt (the spec allows gyroscope
///   OR scroll-position tilt as alternatives — I went with press-based,
///   which is simpler, reliable, and consistent with the same technique
///   already used for the Habits long-press tilt and the Save button)
/// - top-habits list: same staggered fade-in as the Habits screen
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tasksAsync = ref.watch(tasksProvider);
    final completionsAsync = ref.watch(completionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              SegmentedToggle<int>(
                options: const [7, 30],
                value: _rangeDays,
                labelBuilder: (v) => '$v Days',
                onChanged: (v) => setState(() => _rangeDays = v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) => completionsAsync.when(
                    data: (completions) => _StatsBody(
                      tasks: tasks,
                      completions: completions,
                      rangeDays: _rangeDays,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _ErrorBanner(palette: palette),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _ErrorBanner(palette: palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final List<RoutineTask> tasks;
  final Map<String, bool> completions;
  final int rangeDays;

  const _StatsBody({required this.tasks, required this.completions, required this.rangeDays});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final habits = tasks.where((t) => t.isHabit).toList();

    final dayPercents = List.generate(rangeDays, (i) {
      final day = DateTime.now().subtract(Duration(days: rangeDays - 1 - i));
      return completionPercentForDay(tasks, completions, day);
    });
    final overallRate = dayPercents.isEmpty ? 0 : (dayPercents.reduce((a, b) => a + b) / dayPercents.length).round();

    final rankedHabits = habits.toList()
      ..sort((a, b) => currentStreak(habits, completions, b.id).compareTo(currentStreak(habits, completions, a.id)));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TiltStatCard(
                  value: '$overallRate%',
                  label: 'Completion rate',
                  tint: palette.greenTint,
                  valueColor: palette.greenAccent,
                  labelColor: palette.greenText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TiltStatCard(
                  value: '${habits.length}',
                  label: 'Active habits',
                  tint: palette.amberTint,
                  valueColor: palette.amberAccent,
                  labelColor: palette.amberText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'Completion rate over the last $rangeDays days: '
                '${dayPercents.asMap().entries.map((e) => '${_dayLabel(e.key, rangeDays)} ${e.value} percent').join(', ')}',
            child: ExcludeSemantics(
              child: _BarChart(percents: dayPercents, rangeDays: rangeDays),
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Complete tasks to see your trends here.',
                  style: TextStyle(fontSize: 12, color: palette.textMuted)),
            ),
          const SizedBox(height: 20),
          Text('Top habits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.textPrimary)),
          const SizedBox(height: 8),
          if (rankedHabits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No habits yet', style: TextStyle(fontSize: 12, color: palette.textMuted)),
            )
          else
            ...rankedHabits.take(5).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final habit = entry.value;
              final streak = currentStreak(habits, completions, habit.id);
              return StaggeredFadeIn(
                index: entry.key,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 16, child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: palette.textMuted))),
                      const SizedBox(width: 8),
                      Icon(habit.category.icon, size: 15, color: habit.category.accent(palette)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(habit.title, style: const TextStyle(fontSize: 12))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: palette.amberTint, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, size: 12, color: palette.amberAccent),
                            const SizedBox(width: 3),
                            Text('$streak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: palette.amberText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String _dayLabel(int index, int rangeDays) {
    final day = DateTime.now().subtract(Duration(days: rangeDays - 1 - index));
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
  }
}

/// Bars animate their height from 0 up to the target percentage —
/// AnimatedContainer handles the tween; a ValueKey on the range length
/// forces a rebuild (and thus a fresh 0→value animation) when toggling
/// between the 7-day and 30-day views, matching the "grow on every
/// timeframe toggle" spec rather than animating only on first render.
class _BarChart extends StatelessWidget {
  final List<int> percents;
  final int rangeDays;
  const _BarChart({required this.percents, required this.rangeDays});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final showLabels = rangeDays == 7;

    return SizedBox(
      height: 130,
      child: Row(
        key: ValueKey(rangeDays),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(percents.length, (i) {
          final day = DateTime.now().subtract(Duration(days: rangeDays - 1 - i));
          final showLabel = showLabels || i % 5 == 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 100,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _AnimatedBar(percent: percents[i], color: palette.purpleAccent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 12,
                    child: showLabel
                        ? Text(
                            showLabels ? _weekdayLetter(day.weekday) : '${day.day}',
                            style: TextStyle(fontSize: 9, color: palette.textMuted),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  static String _weekdayLetter(int weekday) => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}

class _AnimatedBar extends StatefulWidget {
  final int percent;
  final Color color;
  const _AnimatedBar({required this.percent, required this.color});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> {
  double _height = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _height = widget.percent.clamp(0, 100).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: _height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
      ),
    );
  }
}

/// Stat card with a press-based 3D perspective tilt — the one tasteful
/// depth moment on this screen (see file-level doc comment for why
/// press-based rather than gyroscope).
class _TiltStatCard extends StatefulWidget {
  final String value;
  final String label;
  final Color tint;
  final Color valueColor;
  final Color labelColor;

  const _TiltStatCard({
    required this.value,
    required this.label,
    required this.tint,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  State<_TiltStatCard> createState() => _TiltStatCardState();
}

class _TiltStatCardState extends State<_TiltStatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press(bool down) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    if (down) {
      _controller.animateTo(1.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 120));
    } else {
      _controller.animateBack(0.0, curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 350));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(true),
      onTapCancel: () => _press(false),
      onTapUp: (_) => _press(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(0.035 * t)
            ..translate(0.0, -2.0 * t);
          return Transform(transform: matrix, alignment: Alignment.center, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: widget.tint, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: widget.valueColor)),
              const SizedBox(height: 2),
              Text(widget.label, style: TextStyle(fontSize: 11, color: widget.labelColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppPalette palette;
  const _ErrorBanner({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: palette.coralTint, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: palette.coralAccent),
            const SizedBox(width: 8),
            Text("Couldn't load stats", style: TextStyle(fontSize: 12, color: palette.coralText)),
          ],
        ),
      ),
    );
  }
}

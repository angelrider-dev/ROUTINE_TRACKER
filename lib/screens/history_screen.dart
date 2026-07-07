import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

/// History screen — monthly heatmap + a day-detail panel.
///
/// Animations (see docs/animation-reference/04-calendar-nav-day-detail.png):
/// - month navigation: table_calendar's built-in PageView swipe/slide
///   (the package handles this transition internally; we don't reimplement
///   a custom PageView, since that would duplicate what the package
///   already does correctly)
/// - selecting a day: cell does a brief scale pulse (1.0→1.1→1.0, 150ms),
///   detail card below expands via AnimatedSize + fade
/// - explicitly NO 3D depth anywhere on this screen — a calendar is a
///   fast lookup tool, and tilt/perspective would work against scanning
///   it quickly. This is the "calmest" screen by design.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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
              const Text('History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              tasksAsync.when(
                data: (tasks) => completionsAsync.when(
                  data: (completions) => Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalendar(palette, tasks, completions),
                          const SizedBox(height: 8),
                          _buildLegend(palette),
                          const SizedBox(height: 14),
                          _DayDetailCard(
                            day: _selectedDay,
                            tasks: tasks,
                            completions: completions,
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => _ErrorBanner(palette: palette),
                ),
                loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
                error: (_, __) => _ErrorBanner(palette: palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(AppPalette palette, List<RoutineTask> tasks, Map<String, bool> completions) {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selected, focused) => setState(() {
        _selectedDay = selected;
        _focusedDay = focused;
      }),
      onPageChanged: (focused) => _focusedDay = focused,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 10, color: palette.textMuted),
        weekendStyle: TextStyle(fontSize: 10, color: palette.textMuted),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextStyle: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        leftChevronIcon: Icon(Icons.chevron_left, size: 18, color: palette.textMuted),
        rightChevronIcon: Icon(Icons.chevron_right, size: 18, color: palette.textMuted),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _dayCell(palette, tasks, completions, day, false),
        todayBuilder: (context, day, focusedDay) => _dayCell(palette, tasks, completions, day, false, isToday: true),
        selectedBuilder: (context, day, focusedDay) => _dayCell(palette, tasks, completions, day, true),
        outsideBuilder: (context, day, focusedDay) => Opacity(
          opacity: 0.35,
          child: _dayCell(palette, tasks, completions, day, false),
        ),
      ),
    );
  }

  Widget _dayCell(
    AppPalette palette,
    List<RoutineTask> tasks,
    Map<String, bool> completions,
    DateTime day,
    bool isSelected, {
    bool isToday = false,
  }) {
    final hasEligibleTasks = tasks.any((t) => isScheduledOn(t, day));
    final percent = hasEligibleTasks ? completionPercentForDay(tasks, completions, day) : null;

    return _AnimatedDayCell(
      key: ValueKey(day),
      day: day,
      percent: percent,
      isSelected: isSelected,
      isToday: isToday,
      palette: palette,
    );
  }

  Widget _buildLegend(AppPalette palette) {
    Color bucketColor(int level) => _bucketColor(palette, level);
    return Row(
      children: [
        Text('Less', style: TextStyle(fontSize: 10, color: palette.textMuted)),
        const SizedBox(width: 5),
        ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: bucketColor(i), borderRadius: BorderRadius.circular(3))),
            )),
        Text('More', style: TextStyle(fontSize: 10, color: palette.textMuted)),
      ],
    );
  }
}

Color _bucketColor(AppPalette palette, int level) {
  switch (level) {
    case 0:
      return palette.border;
    case 1:
      return Color.lerp(palette.border, palette.greenAccent, 0.3)!;
    case 2:
      return Color.lerp(palette.border, palette.greenAccent, 0.65)!;
    default:
      return palette.greenAccent;
  }
}

int _bucketFor(int? percent) {
  if (percent == null) return 0;
  if (percent == 0) return 0;
  if (percent < 50) return 1;
  if (percent < 100) return 2;
  return 3;
}

/// A single calendar day cell. Pulses with a brief scale-up (1.0→1.1→1.0,
/// 150ms) the moment it transitions into the selected state — not on
/// every rebuild, only on the true false→true edge.
class _AnimatedDayCell extends StatefulWidget {
  final DateTime day;
  final int? percent;
  final bool isSelected;
  final bool isToday;
  final AppPalette palette;

  const _AnimatedDayCell({
    super.key,
    required this.day,
    required this.percent,
    required this.isSelected,
    required this.isToday,
    required this.palette,
  });

  @override
  State<_AnimatedDayCell> createState() => _AnimatedDayCellState();
}

class _AnimatedDayCellState extends State<_AnimatedDayCell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedDayCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bucket = _bucketFor(widget.percent);
    final bg = _bucketColor(widget.palette, bucket);
    // Text needs to stay legible against both empty (border-color) and
    // fully-filled (accent-color) backgrounds.
    final textColor = bucket >= 2 ? widget.palette.background : widget.palette.textPrimary;

    return Semantics(
      label: '${_monthName(widget.day.month)} ${widget.day.day}'
          '${widget.percent != null ? ', ${widget.percent} percent complete' : ', no tasks scheduled'}',
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected ? Border.all(color: widget.palette.purpleAccent, width: 2) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('${widget.day.day}', style: TextStyle(fontSize: 12, color: textColor)),
              if (widget.isToday)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];
}

/// Expands/fades in below the calendar when a day is selected, showing
/// that day's specific task states (historical — not "today"'s live state).
class _DayDetailCard extends StatelessWidget {
  final DateTime day;
  final List<RoutineTask> tasks;
  final Map<String, bool> completions;

  const _DayDetailCard({required this.day, required this.tasks, required this.completions});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final eligible = tasks.where((t) => isScheduledOn(t, day)).toList();
    final doneCount = eligible.where((t) => isDoneOn(completions, t.id, day)).length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(day),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: palette.purpleTint, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eligible.isEmpty
                    ? '${_weekdayShort(day.weekday)}, ${_monthShort(day.month)} ${day.day}'
                    : '${_weekdayShort(day.weekday)}, ${_monthShort(day.month)} ${day.day} — $doneCount of ${eligible.length} done',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: palette.purpleText),
              ),
              if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('No tasks scheduled this day',
                      style: TextStyle(fontSize: 12, color: palette.purpleAccent)),
                )
              else
                ...eligible.map((t) {
                  final done = isDoneOn(completions, t.id, day);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          done ? Icons.check : Icons.radio_button_unchecked,
                          size: 14,
                          color: done ? palette.purpleAccent : palette.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(t.title, style: TextStyle(fontSize: 12, color: palette.purpleText)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekdayShort(int w) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  static String _monthShort(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _ErrorBanner extends StatelessWidget {
  final AppPalette palette;
  const _ErrorBanner({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: palette.coralTint, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: palette.coralAccent),
              const SizedBox(width: 8),
              Text("Couldn't load history", style: TextStyle(fontSize: 12, color: palette.coralText)),
            ],
          ),
        ),
      ),
    );
  }
}

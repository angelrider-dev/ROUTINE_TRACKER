import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'staggered_fade_in.dart';

const double _pixelsPerHour = 64;
const double _hourLabelWidth = 40;

/// Vertical timeline: hour-gridded, tasks positioned by their scheduledTime,
/// a live now-indicator line, and a separate section below for tasks with
/// no time set (per spec — those never appear ON the timeline itself).
///
/// Design decision, stated plainly: tasks are rendered as fixed-height
/// cards positioned at their start time, not duration-sized blocks — the
/// data model has no `durationMinutes` field, and adding one means a Drift
/// schema migration. Doing that carefully is a real, separate piece of
/// work, not something to bolt on quietly inside a "just add the timeline
/// view" pass — so this deliberately works with what the model already has.
class TimelineView extends StatefulWidget {
  final List<RoutineTask> tasks;
  final Map<String, bool> completions;
  final void Function(RoutineTask task, bool currentlyDone) onToggle;
  final void Function(RoutineTask task)? onEdit;

  const TimelineView({
    super.key,
    required this.tasks,
    required this.completions,
    required this.onToggle,
    this.onEdit,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final _scrollController = ScrollController();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    // Ticks once a minute — enough to keep the now-indicator accurate
    // without repainting more than needed.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToNow());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollToNow() {
    if (_hasAutoScrolled || !_scrollController.hasClients) return;
    _hasAutoScrolled = true;
    final range = _hourRange();
    final targetY = _yFor(TimeOfDay.fromDateTime(_now), range.$1) - 120; // center-ish
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final clamped = targetY.clamp(0.0, _scrollController.position.maxScrollExtent);
    if (reduceMotion) {
      _scrollController.jumpTo(clamped);
    } else {
      _scrollController.animateTo(clamped, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  (int, int) _hourRange() {
    final scheduledHours = widget.tasks
        .where((t) => t.scheduledTime != null)
        .map((t) => t.scheduledTime!.hour);
    final earliest = scheduledHours.isEmpty ? 6 : scheduledHours.reduce((a, b) => a < b ? a : b);
    final latest = scheduledHours.isEmpty ? 22 : scheduledHours.reduce((a, b) => a > b ? a : b);
    return (earliest < 6 ? earliest : 6, latest > 22 ? latest + 1 : 22);
  }

  double _yFor(TimeOfDay time, int rangeStart) {
    return (time.hour - rangeStart) * _pixelsPerHour + (time.minute / 60) * _pixelsPerHour;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheduled = widget.tasks.where((t) => t.scheduledTime != null).toList()
      ..sort((a, b) {
        final aMin = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
        final bMin = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
        return aMin.compareTo(bMin);
      });
    final unscheduled = widget.tasks.where((t) => t.scheduledTime == null).toList();

    if (scheduled.isEmpty && unscheduled.isEmpty) {
      return const SizedBox.shrink(); // Today screen's own empty state covers this
    }

    final (rangeStart, rangeEnd) = _hourRange();
    final totalHeight = (rangeEnd - rangeStart) * _pixelsPerHour;
    final showNowIndicator = _now.hour >= rangeStart && _now.hour < rangeEnd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: totalHeight + 20,
              child: Stack(
                children: [
                  // Hour gridlines + labels
                  for (int h = rangeStart; h <= rangeEnd; h++)
                    Positioned(
                      top: (h - rangeStart) * _pixelsPerHour,
                      left: 0,
                      right: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: _hourLabelWidth,
                            child: Text(_hourLabel(h),
                                style: TextStyle(fontSize: 10, color: palette.textMuted)),
                          ),
                          Expanded(
                            child: Container(height: 0.5, color: palette.borderSubtle, margin: const EdgeInsets.only(top: 6)),
                          ),
                        ],
                      ),
                    ),

                  // Task cards, staggered fade-in on first appearance
                  for (int i = 0; i < scheduled.length; i++)
                    Positioned(
                      top: _yFor(scheduled[i].scheduledTime!, rangeStart) - 12,
                      left: _hourLabelWidth + 8,
                      right: 0,
                      child: StaggeredFadeIn(
                        index: i,
                        delayPerItemMs: 30,
                        child: _TimelineTaskCard(
                          task: scheduled[i],
                          done: _isDone(scheduled[i]),
                          onToggle: () => widget.onToggle(scheduled[i], _isDone(scheduled[i])),
                          onEdit: widget.onEdit == null ? null : () => widget.onEdit!(scheduled[i]),
                        ),
                      ),
                    ),

                  // Live now-indicator
                  if (showNowIndicator)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      top: _yFor(TimeOfDay.fromDateTime(_now), rangeStart),
                      left: _hourLabelWidth,
                      right: 0,
                      child: _NowIndicator(color: palette.coralAccent),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (unscheduled.isNotEmpty)
          _UnscheduledSection(tasks: unscheduled, isDone: _isDone, onToggle: widget.onToggle, onEdit: widget.onEdit),
      ],
    );
  }

  bool _isDone(RoutineTask task) {
    final d = DateTime.now();
    final key = '${task.id}|${d.year}-${d.month}-${d.day}';
    return widget.completions[key] ?? false;
  }

  static String _hourLabel(int hour) {
    final h = hour % 24;
    final period = h < 12 ? 'AM' : 'PM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayHour $period';
  }
}

/// A live, gently pulsing dot + line marking the current time — the one
/// piece of ambient motion on this view, since it represents something
/// that's actually always moving (time itself), not decoration.
class _NowIndicator extends StatefulWidget {
  final Color color;
  const _NowIndicator({required this.color});

  @override
  State<_NowIndicator> createState() => _NowIndicatorState();
}

class _NowIndicatorState extends State<_NowIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (!reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + (0.3 * Curves.easeInOut.transform(_controller.value));
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Container(height: 1.5, color: widget.color)),
      ],
    );
  }
}

class _TimelineTaskCard extends StatefulWidget {
  final RoutineTask task;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;

  const _TimelineTaskCard({required this.task, required this.done, required this.onToggle, this.onEdit});

  @override
  State<_TimelineTaskCard> createState() => _TimelineTaskCardState();
}

class _TimelineTaskCardState extends State<_TimelineTaskCard> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _pressScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_pressController);
  }

  @override
  void didUpdateWidget(covariant _TimelineTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.done && widget.done) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleLongPress() async {
    if (widget.onEdit == null) return;
    HapticFeedback.mediumImpact();

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      widget.onEdit!.call();
      return;
    }

    await _pressController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 60));
    if (mounted) widget.onEdit!.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final category = widget.task.category;
    final tint = category.tint(palette);
    final accent = category.accent(palette);

    return GestureDetector(
      onTap: widget.onToggle,
      onLongPress: widget.onEdit != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _pressController]),
        builder: (context, child) {
          final bounce = 1.0 + (0.03 * Curves.easeOut.transform(_controller.value));
          return Transform.scale(scale: bounce * _pressScale.value, alignment: Alignment.centerLeft, child: child);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.done ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.done ? Icons.check_circle : category.icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: category.text(palette),
                      decoration: widget.done ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                    child: Text(widget.task.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnscheduledSection extends StatelessWidget {
  final List<RoutineTask> tasks;
  final bool Function(RoutineTask) isDone;
  final void Function(RoutineTask, bool) onToggle;
  final void Function(RoutineTask)? onEdit;

  const _UnscheduledSection({required this.tasks, required this.isDone, required this.onToggle, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: palette.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No time set', style: TextStyle(fontSize: 11, color: palette.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tasks.map((t) {
              final done = isDone(t);
              return _TimelineTaskCard(
                task: t,
                done: done,
                onToggle: () => onToggle(t, done),
                onEdit: onEdit == null ? null : () => onEdit!(t),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

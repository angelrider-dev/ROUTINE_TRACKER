import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/task_tile.dart';
import '../widgets/timeline_view.dart';

enum _ViewMode { list, timeline }

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  final List<RoutineTask> _tasks = [];
  bool _initialized = false;
  _ViewMode _viewMode = _ViewMode.list;

  void _syncList(List<RoutineTask> incoming) {
    if (!_initialized) {
      _tasks.addAll(incoming);
      _initialized = true;
      return;
    }

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    for (int i = _tasks.length - 1; i >= 0; i--) {
      final stillPresent = incoming.any((t) => t.id == _tasks[i].id);
      if (!stillPresent) {
        final removed = _tasks.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedTile(removed, animation, reduceMotion),
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
        );
      }
    }

    for (int i = 0; i < incoming.length; i++) {
      final alreadyThere = _tasks.any((t) => t.id == incoming[i].id);
      if (!alreadyThere) {
        _tasks.insert(i, incoming[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
        );
      }
    }
  }

  Widget _buildRemovedTile(RoutineTask task, Animation<double> animation, bool reduceMotion) {
    if (reduceMotion) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskTile(task: task, done: false, onToggle: () {}),
        ),
      ),
    );
  }

  Widget _buildListBody(
    AsyncValue<List<RoutineTask>> tasksAsync,
    AsyncValue<Map<String, bool>> completionsAsync,
  ) {
    return tasksAsync.when(
      data: (allTasks) {
        final tasks = allTasks.where((t) => isScheduledOn(t, DateTime.now())).toList();
        if (!_initialized) _syncList(tasks);
        if (_tasks.isEmpty) return const _EmptyState();

        return completionsAsync.when(
          data: (completions) => AnimatedList(
            key: _listKey,
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            initialItemCount: _tasks.length,
            itemBuilder: (context, index, animation) {
              if (index >= _tasks.length) return const SizedBox.shrink();
              final task = _tasks[index];
              final done = isDoneOn(completions, task.id, DateTime.now());
              return SizeTransition(
                sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TaskTile(
                      task: task,
                      done: done,
                      onToggle: () => ref.read(taskActionsProvider).toggle(task.id, DateTime.now(), done),
                      onEdit: () => context.push('/add-task', extra: task),
                    ),
                  ),
                ),
              );
            },
          ),
          loading: () => const _ListSkeleton(),
          error: (_, __) => const _ErrorBanner(message: "Couldn't load today's tasks"),
        );
      },
      loading: () => const _ListSkeleton(),
      error: (_, __) => const _ErrorBanner(message: "Couldn't load today's tasks"),
    );
  }

  Widget _buildTimelineBody(
    AsyncValue<List<RoutineTask>> tasksAsync,
    AsyncValue<Map<String, bool>> completionsAsync,
  ) {
    return tasksAsync.when(
      data: (allTasks) {
        final tasks = allTasks.where((t) => isScheduledOn(t, DateTime.now())).toList();
        if (tasks.isEmpty) return const _EmptyState();

        return completionsAsync.when(
          data: (completions) => TimelineView(
            tasks: tasks,
            completions: completions,
            onToggle: (task, currentlyDone) =>
                ref.read(taskActionsProvider).toggle(task.id, DateTime.now(), currentlyDone),
            onEdit: (task) => context.push('/add-task', extra: task),
          ),
          loading: () => const _ListSkeleton(),
          error: (_, __) => const _ErrorBanner(message: "Couldn't load today's tasks"),
        );
      },
      loading: () => const _ListSkeleton(),
      error: (_, __) => const _ErrorBanner(message: "Couldn't load today's tasks"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final completionsAsync = ref.watch(completionsProvider);

    ref.listen<AsyncValue<List<RoutineTask>>>(tasksProvider, (previous, next) {
      next.whenData((tasks) {
        final todayTasks = tasks.where((t) => isScheduledOn(t, DateTime.now())).toList();
        _syncList(todayTasks);
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 16),
              tasksAsync.when(
                data: (allTasks) {
                  final tasks = allTasks.where((t) => isScheduledOn(t, DateTime.now())).toList();
                  return completionsAsync.when(
                    data: (completions) => _ProgressCard(
                      progress: todayProgress(tasks, completions),
                      doneCount: tasks.where((t) => isDoneOn(completions, t.id, DateTime.now())).length,
                      total: tasks.length,
                    ),
                    loading: () => const _ProgressCardSkeleton(),
                    error: (_, __) => const _ErrorBanner(message: "Couldn't load progress"),
                  );
                },
                loading: () => const _ProgressCardSkeleton(),
                error: (_, __) => const _ErrorBanner(message: "Couldn't load progress"),
              ),
              const SizedBox(height: 12),
              SegmentedToggle<_ViewMode>(
                options: _ViewMode.values,
                value: _viewMode,
                labelBuilder: (m) => m == _ViewMode.list ? 'List' : 'Timeline',
                onChanged: (m) => setState(() => _viewMode = m),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _viewMode == _ViewMode.list
                      ? KeyedSubtree(key: const ValueKey('list'), child: _buildListBody(tasksAsync, completionsAsync))
                      : KeyedSubtree(
                          key: const ValueKey('timeline'),
                          child: _buildTimelineBody(tasksAsync, completionsAsync),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final weekday = _weekdayName(DateTime.now().weekday);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weekday, style: TextStyle(fontSize: 12, color: palette.textMuted)),
            const Text('Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          ],
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: palette.purpleTint,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/settings'),
              child: Icon(Icons.person, size: 16, color: palette.purpleAccent),
            ),
          ),
        ),
      ],
    );
  }

  static String _weekdayName(int weekday) =>
      const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int doneCount;
  final int total;

  const _ProgressCard({required this.progress, required this.doneCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: palette.purpleTint, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ProgressRing(progress: progress.clamp(0, 1)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '$doneCount of $total tasks done today',
                child: ExcludeSemantics(
                  child: Text('$doneCount of $total done',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.purpleText)),
                ),
              ),
              Text('${total - doneCount} tasks left today',
                  style: TextStyle(fontSize: 12, color: palette.purpleAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCardSkeleton extends StatelessWidget {
  const _ProgressCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(color: context.palette.surfaceRaised, borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Container(
        height: 50,
        decoration: BoxDecoration(color: palette.surfaceRaised, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.list_alt, size: 40, color: palette.textMuted),
          const SizedBox(height: 12),
          Text('No tasks yet', style: TextStyle(fontSize: 14, color: palette.textSecondary)),
          const SizedBox(height: 4),
          Text('Add your first task to get started', style: TextStyle(fontSize: 12, color: palette.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

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
          Expanded(child: Text(message, style: TextStyle(fontSize: 12, color: palette.coralText))),
        ],
      ),
    );
  }
}
